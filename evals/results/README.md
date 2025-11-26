# 📊 Test Results Dashboard

Interactive dashboard for visualizing OpenCode agent test results.

## ⚡ Quick Reference

```bash
# Run tests
cd evals/framework && npm run eval:sdk -- --agent=opencoder

# View dashboard (auto-opens browser, auto-shuts down)
cd evals/results && ./serve.sh
```

That's it! 🎉

---

## Quick Start

1. **Run Tests:**
   ```bash
   cd evals/framework
   npm run eval:sdk -- --agent=opencoder
   npm run eval:sdk -- --agent=openagent
   ```

2. **View Dashboard:**
   
   **Option A: One-Command Solution (Easiest)** ⭐
   ```bash
   cd evals/results
   ./serve.sh
   ```
   - Auto-opens browser
   - Loads dashboard
   - Auto-shuts down after 15 seconds
   - Dashboard stays cached in browser!
   
   **Custom timeout:**
   ```bash
   ./serve.sh 8000 30  # Port 8000, 30 second timeout
   ```
   
   **Option B: Keep Server Running**
   ```bash
   cd evals/results
   python3 -m http.server 8000
   ```
   Press Ctrl+C to stop manually
   
   **Option C: Direct File Access**
   ```bash
   open evals/results/index.html
   ```
   ⚠️ Note: Some browsers block loading JSON from local files. If you see an error, use Option A or B.

## Features

### 📈 Overview Stats
- **Total Tests** - Count across all agents
- **Pass Rate** - Percentage of passing tests
- **Failed Tests** - Number of failures
- **Avg Duration** - Average test execution time

### 📊 Trend Chart
- Visual representation of pass rate over time
- Shows last 30 days of test runs
- Helps identify regressions

### 🔍 Filters
- **Agent** - Filter by openagent, opencoder, etc.
- **Category** - Developer, business, creative, edge-case
- **Status** - All, passed only, or failed only
- **Time Range** - Latest, today, last 7 days, last 30 days

### 🔎 Search
- Real-time search across test IDs
- Case-insensitive matching

### 📋 Test Table
- **Sortable Columns** - Click any header to sort
- **Expandable Rows** - Click a row to see details
- **Violation Details** - See error messages and severity

### 🌙 Dark Mode
- Toggle with moon/sun icon in header
- Preference saved to localStorage
- Easy on the eyes for long sessions

### 📥 Export
- Export filtered results to CSV
- Includes all test metadata
- Perfect for external analysis

## File Structure

```
results/
├── index.html              # Dashboard (open this)
├── serve.sh                # Helper script to start HTTP server
├── latest.json             # Most recent test run
├── history/
│   └── 2025-11/
│       ├── 26-115759-opencoder.json
│       └── 26-115850-openagent.json
├── .gitignore              # Retention policy
└── README.md               # This file
```

## JSON Format

Each result file contains:

```json
{
  "meta": {
    "timestamp": "2025-11-26T11:59:36.365Z",
    "agent": "openagent",
    "model": "opencode/grok-code-fast",
    "framework_version": "0.1.0",
    "git_commit": "f872007"
  },
  "summary": {
    "total": 8,
    "passed": 6,
    "failed": 2,
    "duration_ms": 32450,
    "pass_rate": 0.75
  },
  "by_category": {
    "developer": { "passed": 5, "total": 6 },
    "business": { "passed": 1, "total": 1 },
    "edge-case": { "passed": 0, "total": 1 }
  },
  "tests": [
    {
      "id": "task-simple-001",
      "category": "developer",
      "passed": true,
      "duration_ms": 4200,
      "events": 23,
      "approvals": 2,
      "violations": {
        "total": 0,
        "errors": 0,
        "warnings": 0
      }
    }
  ]
}
```

## Retention Policy

Results are automatically managed:

- ✅ **Latest Run** - Always kept (`latest.json`)
- ✅ **Current Month** - All results committed to git
- ✅ **Previous Month** - All results committed to git
- ❌ **Older than 60 days** - Kept locally, not committed

This keeps the repo size manageable while preserving recent history.

## Tips

### Quick View Workflow
The fastest way to view results:
```bash
cd evals/results && ./serve.sh
```
- ✅ Opens browser automatically
- ✅ Loads all data
- ✅ Shuts down after 15 seconds
- ✅ Dashboard stays functional (data cached)
- ✅ No manual cleanup needed

**Want to keep exploring?** Press Ctrl+C during countdown to keep server running.

### Comparing Agents
1. Set **Time Range** to "Latest Run"
2. Set **Agent** to "All Agents"
3. Compare pass rates and durations

### Finding Flaky Tests
1. Set **Time Range** to "Last 30 Days"
2. Look for tests that alternate between pass/fail
3. Check violation details for patterns

### Tracking Improvements
1. Run tests regularly (daily/weekly)
2. Watch the trend chart for improvements
3. Export CSV for deeper analysis

### Debugging Failures
1. Filter **Status** to "Failed Only"
2. Click on a failed test row
3. Review violation details
4. Check error messages and severity

## Browser Compatibility

- ✅ Chrome/Edge (recommended)
- ✅ Firefox
- ✅ Safari
- ⚠️ IE11 (not supported)

## Performance

- **Dashboard Size:** ~31KB (no dependencies except Chart.js CDN)
- **Load Time:** < 1 second for 100 tests
- **Memory:** Minimal (pure JavaScript, no frameworks)

## How It Works

### Auto-Shutdown Feature
The `serve.sh` script:
1. Starts HTTP server on port 8000
2. Opens dashboard in your browser
3. Waits 15 seconds for data to load
4. Shuts down server automatically
5. Dashboard continues working (data cached in browser)

**Why does it still work after shutdown?**
- The browser caches the JSON data
- All filtering/sorting happens in JavaScript
- No server needed after initial load
- Refresh the page to load new data (server will need to restart)

### Stopping Manually
If you start the server manually:
```bash
# Find the process
lsof -ti:8000

# Kill it
kill $(lsof -ti:8000)
```

Or just press Ctrl+C in the terminal.

## Troubleshooting

### Dashboard shows "No results found"
- Run tests first: `npm run eval:sdk`
- Check that `latest.json` exists
- Refresh the page

### Chart not displaying
- Check browser console for errors
- Ensure Chart.js CDN is accessible
- Try refreshing the page

### Dark mode not persisting
- Check browser localStorage is enabled
- Clear cache and try again

## Future Enhancements

Potential improvements:
- [ ] Historical comparison (compare two runs)
- [ ] Test duration trends per test
- [ ] Violation type breakdown chart
- [ ] Agent performance comparison chart
- [ ] Auto-refresh option
- [ ] Shareable URLs with filters
- [ ] CI/CD badge generation

## Contributing

To improve the dashboard:

1. Edit `index.html` (all code is in one file)
2. Test locally by opening in browser
3. Submit PR with description of changes

## License

MIT - Same as OpenCode Agents project
