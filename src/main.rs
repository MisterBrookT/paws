use std::env;
use std::fs;
use std::io::{self, Read, Write};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

use crossterm::{
    event::{self, Event, KeyCode, KeyEventKind},
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
    ExecutableCommand,
};
use portable_pty::{CommandBuilder, NativePtySystem, PtySize, PtySystem};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Alignment, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Clear, Paragraph},
    Frame, Terminal,
};

const SIGNAL_PATH: &str = "/tmp/paws-signal";
const GAME_COLS: u16 = 80;
const GAME_ROWS: u16 = 24;
const POLL_MS: u64 = 50;

struct Game {
    name: &'static str,
    cmd: &'static str,
    brew_hint: &'static str,
}

const GAMES: &[Game] = &[
    Game {
        name: "Vitetris (Tetris)",
        cmd: "tetris",
        brew_hint: "brew install vitetris",
    },
    Game {
        name: "Jump High",
        cmd: "jump-high",
        brew_hint: "cargo install --git https://github.com/MisterBrookT/jump-high",
    },
];

fn is_installed(cmd: &str) -> bool {
    env::var_os("PATH")
        .map(|paths| env::split_paths(&paths).any(|dir| dir.join(cmd).is_file()))
        .unwrap_or(false)
}

fn epoch_day() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs()
        / 86400
}

fn pick_index(day: u64, count: usize) -> usize {
    (day as usize) % count
}

enum AppState {
    Running,
    Paused { started: Instant },
}

fn main() -> io::Result<()> {
    // --list mode
    if env::args().any(|a| a == "--list") {
        println!("Paws game list:");
        for g in GAMES {
            let status = if is_installed(g.cmd) { "✓" } else { "✗" };
            println!(
                "  [{status}] {:<20} cmd: {:<10} install: {}",
                g.name, g.cmd, g.brew_hint
            );
        }
        return Ok(());
    }

    // Pick game
    let installed: Vec<&Game> = GAMES.iter().filter(|g| is_installed(g.cmd)).collect();
    if installed.is_empty() {
        println!("🐾 No games installed! Install one to play:");
        for g in GAMES {
            println!("  {} → {}", g.name, g.brew_hint);
        }
        return Ok(());
    }
    let idx = pick_index(epoch_day(), installed.len());
    let game = installed[idx];

    // Clean up any stale signal
    let _ = fs::remove_file(SIGNAL_PATH);

    // Spawn game in PTY
    let pty_system = NativePtySystem::default();
    let pair = pty_system
        .openpty(PtySize {
            rows: GAME_ROWS,
            cols: GAME_COLS,
            pixel_width: 0,
            pixel_height: 0,
        })
        .map_err(|e| io::Error::new(io::ErrorKind::Other, e.to_string()))?;

    let mut cmd = CommandBuilder::new(game.cmd);
    cmd.env("TERM", "xterm-256color");

    let _child = pair
        .slave
        .spawn_command(cmd)
        .map_err(|e| io::Error::new(io::ErrorKind::Other, e.to_string()))?;
    drop(pair.slave); // close slave side in parent

    let mut pty_writer = pair.master.take_writer()
        .map_err(|e| io::Error::new(io::ErrorKind::Other, e.to_string()))?;
    let mut pty_reader = pair.master.try_clone_reader()
        .map_err(|e| io::Error::new(io::ErrorKind::Other, e.to_string()))?;

    // VT100 parser for game screen
    let parser = Arc::new(Mutex::new(vt100::Parser::new(GAME_ROWS, GAME_COLS, 0)));
    let parser_clone = Arc::clone(&parser);

    // Reader thread: PTY → vt100 parser
    std::thread::spawn(move || {
        let mut buf = [0u8; 4096];
        loop {
            match pty_reader.read(&mut buf) {
                Ok(0) => break,
                Ok(n) => {
                    parser_clone.lock().unwrap().process(&buf[..n]);
                }
                Err(_) => break,
            }
        }
    });

    // Setup terminal
    enable_raw_mode()?;
    io::stdout().execute(EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(io::stdout());
    let mut terminal = Terminal::new(backend)?;

    let mut state = AppState::Running;
    let result = run_loop(&mut terminal, &parser, &mut pty_writer, &mut state);

    // Cleanup
    disable_raw_mode()?;
    io::stdout().execute(LeaveAlternateScreen)?;
    drop(pair.master);

    result
}

fn run_loop(
    terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
    parser: &Arc<Mutex<vt100::Parser>>,
    pty_writer: &mut Box<dyn Write + Send>,
    state: &mut AppState,
) -> io::Result<()> {
    loop {
        // Draw
        terminal.draw(|f| {
            draw_game(f, parser);
            if let AppState::Paused { started } = state {
                draw_overlay(f, *started);
            }
        })?;

        // Check countdown expiry
        if let AppState::Paused { started } = state {
            if started.elapsed() >= Duration::from_secs(3) {
                ack_and_exit()?;
                return Ok(());
            }
        }

        // Poll events
        if event::poll(Duration::from_millis(POLL_MS))? {
            if let Event::Key(key) = event::read()? {
                if key.kind != KeyEventKind::Press {
                    continue;
                }
                match state {
                    AppState::Running => {
                        // Forward key to PTY
                        if let Some(bytes) = key_to_bytes(key.code) {
                            let _ = pty_writer.write_all(&bytes);
                            let _ = pty_writer.flush();
                        }
                    }
                    AppState::Paused { .. } => {
                        if key.code == KeyCode::Enter {
                            ack_and_exit()?;
                            return Ok(());
                        }
                    }
                }
            }
        }

        // Poll signal file
        if let AppState::Running = state {
            if let Ok(content) = fs::read_to_string(SIGNAL_PATH) {
                let sig = content.trim();
                if sig == "done" {
                    let _ = fs::remove_file(SIGNAL_PATH);
                    *state = AppState::Paused {
                        started: Instant::now(),
                    };
                } else if sig == "busy" {
                    let _ = fs::remove_file(SIGNAL_PATH);
                    // no-op, game is already showing
                }
            }
        }
    }
}

fn draw_game(f: &mut Frame, parser: &Arc<Mutex<vt100::Parser>>) {
    let area = f.area();

    // Dark background
    f.render_widget(
        Block::default().style(Style::default().bg(Color::Black)),
        area,
    );

    // Center the game area
    let game_area = centered_rect(GAME_COLS, GAME_ROWS, area);

    let screen = parser.lock().unwrap();
    let mut lines: Vec<Line> = Vec::with_capacity(GAME_ROWS as usize);

    for row in 0..GAME_ROWS {
        let mut spans: Vec<Span> = Vec::new();
        let mut col = 0u16;
        while col < GAME_COLS {
            let cell = screen.screen().cell(row, col).unwrap();
            let ch = if cell.has_contents() {
                cell.contents()
            } else {
                " ".to_string()
            };

            let mut style = Style::default();
            let fg = cell.fgcolor();
            let bg = cell.bgcolor();
            style = style.fg(vt_color_to_ratatui(fg));
            style = style.bg(vt_color_to_ratatui(bg));
            if cell.bold() {
                style = style.add_modifier(Modifier::BOLD);
            }
            if cell.underline() {
                style = style.add_modifier(Modifier::UNDERLINED);
            }
            if cell.inverse() {
                style = style.add_modifier(Modifier::REVERSED);
            }

            let width = unicode_width(&ch);
            spans.push(Span::styled(ch, style));
            col += width.max(1) as u16;
        }
        lines.push(Line::from(spans));
    }

    let paragraph = Paragraph::new(lines);
    f.render_widget(paragraph, game_area);
}

fn draw_overlay(f: &mut Frame, started: Instant) {
    let area = f.area();
    let elapsed = started.elapsed().as_secs();
    let remaining = 3u64.saturating_sub(elapsed);

    let overlay_w = 30u16.min(area.width);
    let overlay_h = 7u16.min(area.height);
    let overlay_area = centered_rect(overlay_w, overlay_h, area);

    // Semi-transparent overlay (dark bg)
    f.render_widget(Clear, overlay_area);
    let block = Block::bordered()
        .style(Style::default().bg(Color::Rgb(30, 30, 40)).fg(Color::White));

    let countdown = format!("{}...", remaining);
    let text = vec![
        Line::from(""),
        Line::from(Span::styled(
            "🐾 Agent 完成了",
            Style::default()
                .fg(Color::Yellow)
                .add_modifier(Modifier::BOLD),
        )),
        Line::from(""),
        Line::from(Span::styled(
            "按 Enter 返回 Agent",
            Style::default().fg(Color::White),
        )),
        Line::from(Span::styled(
            countdown,
            Style::default().fg(Color::Gray),
        )),
    ];

    let paragraph = Paragraph::new(text)
        .block(block)
        .alignment(Alignment::Center);
    f.render_widget(paragraph, overlay_area);
}

fn centered_rect(w: u16, h: u16, area: Rect) -> Rect {
    let x = area.x + area.width.saturating_sub(w) / 2;
    let y = area.y + area.height.saturating_sub(h) / 2;
    Rect::new(x, y, w.min(area.width), h.min(area.height))
}

fn ack_and_exit() -> io::Result<()> {
    fs::write(SIGNAL_PATH, "done")?;
    Ok(())
}

fn key_to_bytes(code: KeyCode) -> Option<Vec<u8>> {
    match code {
        KeyCode::Char(c) => {
            let mut buf = [0u8; 4];
            let s = c.encode_utf8(&mut buf);
            Some(s.as_bytes().to_vec())
        }
        KeyCode::Enter => Some(b"\r".to_vec()),
        KeyCode::Backspace => Some(b"\x7f".to_vec()),
        KeyCode::Tab => Some(b"\t".to_vec()),
        KeyCode::Esc => Some(b"\x1b".to_vec()),
        KeyCode::Up => Some(b"\x1b[A".to_vec()),
        KeyCode::Down => Some(b"\x1b[B".to_vec()),
        KeyCode::Right => Some(b"\x1b[C".to_vec()),
        KeyCode::Left => Some(b"\x1b[D".to_vec()),
        KeyCode::Home => Some(b"\x1b[H".to_vec()),
        KeyCode::End => Some(b"\x1b[F".to_vec()),
        KeyCode::Delete => Some(b"\x1b[3~".to_vec()),
        _ => None,
    }
}

fn vt_color_to_ratatui(color: vt100::Color) -> Color {
    match color {
        vt100::Color::Default => Color::Reset,
        vt100::Color::Idx(i) => Color::Indexed(i),
        vt100::Color::Rgb(r, g, b) => Color::Rgb(r, g, b),
    }
}

fn unicode_width(s: &str) -> usize {
    // Simple: count chars. For CJK we'd need unicode-width crate but keep deps minimal.
    s.chars().count()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn pick_index_deterministic() {
        assert_eq!(pick_index(19874, 3), pick_index(19874, 3));
        let results: Vec<usize> = (0..3).map(|d| pick_index(d, 3)).collect();
        assert_eq!(results, vec![0, 1, 2]);
    }

    #[test]
    fn centered_rect_works() {
        let area = Rect::new(0, 0, 100, 40);
        let r = centered_rect(80, 24, area);
        assert_eq!(r.x, 10);
        assert_eq!(r.y, 8);
        assert_eq!(r.width, 80);
        assert_eq!(r.height, 24);
    }

    #[test]
    fn key_to_bytes_basic() {
        assert_eq!(key_to_bytes(KeyCode::Char('a')), Some(b"a".to_vec()));
        assert_eq!(key_to_bytes(KeyCode::Enter), Some(b"\r".to_vec()));
        assert_eq!(key_to_bytes(KeyCode::Up), Some(b"\x1b[A".to_vec()));
    }
}
