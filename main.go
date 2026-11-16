package main

import (
	"fmt"
	"os"
	"time"

	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
)

type model struct {
	w, h  int
	frame int
}

type tickMsg time.Time

func tick() tea.Cmd {
	return tea.Tick(100*time.Millisecond, func(t time.Time) tea.Msg { return tickMsg(t) })
}

func initialModel() model {
	return model{}
}

func (m model) Init() tea.Cmd {
	return tick()
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {

	case tea.WindowSizeMsg:
		m.w, m.h = msg.Width, msg.Height

	case tickMsg:
		m.frame++
		return m, tick()

	case tea.KeyPressMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			return m, tea.Quit
		}
	}

	return m, nil
}

func (m model) View() tea.View {
	if m.w == 0 {
		// no centering cause we, uhh, dont know the screen size yet :catyep:
		return newView("loading...")
	}

	s := fmt.Sprintf("%d x %d\n frames: %d", m.w, m.h, m.frame)
	s = lipgloss.Place(m.w, m.h, lipgloss.Center, lipgloss.Center, s)

	return newView(s)
}

func newView(s string) tea.View {
	view := tea.NewView(s)

	view.AltScreen = true
	view.WindowTitle = "nervtop"

	return view
}

func main() {
	p := tea.NewProgram(initialModel())
	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "nervtop: %v\n", err)
		os.Exit(1)
	}
}
