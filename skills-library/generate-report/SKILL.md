---
name: generate-report
description: Generate weekly weather reports using Open-Meteo API (free, no API key required) and PDF generation. Use when user asks to create a weather report or build a weather PDF.
category: infrastructure
path: agentic
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
env_vars: []
triggers: manual
---

# Weekly Weather Report Generator

## Goal
Generate a professional PDF weather report using real-time data from Open-Meteo API (free, no API key required). The report uses the "Orange and Black Modern Annual Report" template style.

## Inputs
- **Week Start Date** (optional): Start date for the report period (defaults to current week)
- **Cities** (optional): List of cities to include (defaults to configured city list)

## Default Configuration
Configure the default city list in the script. Example regional groupings:
- **[REGION_1_NAME]**: [CITY_1], [CITY_2]
- **[REGION_2_NAME]**: [CITY_3], [CITY_4], [CITY_5]
- Add as many regions/cities as needed

## Scripts
All scripts are in `./scripts/`:
- `fetch_weather.py` - Fetches weather data from Open-Meteo API (no API key needed)
- `generate_report_pdf.py` - Generates the styled PDF report

## Process

### 1. Fetch Weather Data
```bash
python3 ./scripts/fetch_weather.py --output .tmp/weather_data.json
```

Optional parameters:
- `--cities "City1,City2,City3"` - Custom city list
- `--days 7` - Number of forecast days (default: 7, max: 16)

### 2. Generate PDF Report
```bash
python3 ./scripts/generate_report_pdf.py \
  --input .tmp/weather_data.json \
  --output .tmp/weekly_weather_report.pdf \
  --template ".tmp/Orange and Black Modern Annual Report.pdf"
```

### 3. Review and Deliver
- Open `.tmp/weekly_weather_report.pdf` to verify
- Upload to Google Drive or send via email if requested

## Report Structure (Matching Template)
1. **Cover Page**: Title with date range
2. **Table of Contents**: Regional sections listed
3. **National Overview**: Summary of weather patterns
4. **Regional Highlights**: Key metrics (avg temp, precipitation, extremes)
5. **Regional Sections**: Detailed city-by-city data
6. **7-Day Outlook**: Forecast summary with trends
7. **Weather Alerts**: Any active warnings/advisories
8. **Data Sources**: Open-Meteo attribution

## Output
**Primary deliverable**: PDF report at `.tmp/weekly_weather_report.pdf`

The report includes:
- Current conditions for each city
- 7-day forecast with highs/lows
- Precipitation amounts
- Regional comparisons

## Error Handling
- **City not found**: Skip city, log warning, continue
- **Network error**: Retry up to 3 times with backoff
- **Missing data**: Use "N/A" placeholders

## Environment
**No API key required!** Open-Meteo is free and open-source.

Data source: https://open-meteo.com/
