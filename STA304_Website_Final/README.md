# STA304 Student AI Use Survey

An original, modular R Shiny research website for the Null Hypothesis group's STA304H5 project. This editable build integrates both teammate figures and uses the group's actual survey responses.

**Public Posit Connect Cloud URL:** not deployed yet. Replace this sentence with the verified public URL after E completes deployment.

## Run locally

1. Extract this folder, keeping `app.R`, `R/`, `www/`, and `data/` together.
2. In RStudio, set this folder as the working directory.
3. Run `source("install_packages.R")` once if packages are missing.
4. Open `app.R` and click **Run App**, or run `source("launch_app.R")`.

The launcher serves the app at `http://127.0.0.1:3864` on the local computer. This is not the public submission URL.

## Division of work

| Owner | Files | Stable integration interface |
| --- | --- | --- |
| A | `app.R`, `www/styles.css`, `www/favicon.svg`, `R/config.R` | Application layout, navigation, shared navy-and-white design and module wiring |
| B | `R/tools_B.R` | `toolsUI(id, survey)`; `toolsServer(id, data, before_tool, palette)` |
| C | `R/usage_C.R` | `usageUI(id, data)`; `usageServer(id, data, palette)` |
| D | `R/study_D.R` | `studyUI(id)`; `studyServer(id, data, centre)` |
| E | `R/filters_E.R`, deployment files | `filtersUI(id, data)`; `filtersServer(id, data, with_reference = TRUE)` returns filtered data and the pre-tool reference for Figure 1 |
| Shared | `R/helpers.R`, `data/survey.csv` | Data definitions, eligibility and reusable chart styling |

`data` passed to the B/C/D servers is a **reactive expression**: use `data()` inside `renderPlot()`, `renderUI()` or `reactive()`. Do not read the CSV again inside a module. Use `NS(id)` for input/output IDs. Preserve function signatures so A can integrate new modules without rewriting the application.

## Features in this sample

- The tabs are numbered in order from 01 Overview to 05 Data explorer.
- Overview uses the same heading and chart styles as the other tabs. Its primary-tool chart and reading panel use the current sidebar selection.
- One shared filter state; respondent counts, figures, tables, interpretations and exploratory tests update together.
- Figure 1 adapts the teammate's `Figure1_Shiny.R` into stacked bars by academic purpose with counts, percentages and a summary table. `Other AI` groups DeepSeek and Yuanbao only in this figure.
- Figure 2 adapts the teammate's `app.R` into a weekly-hours histogram with frequency/density, bin width and axis limits. Use the sidebar's **Future tool choice** filter to view All, Stay or Switch responses. Check **Set Y-axis limits manually** to reveal the **Y-axis maximum** slider.
- The sidebar's **Chart palette (both figures)** setting applies to Figures 1 and 2 and stays selected when switching tabs. The options are Navy, Grayscale and Pastel. Edit these colours in `FIGURE_PALETTES` in `R/config.R`.
- Searchable/sortable response table, aggregate-summary download, reset filters and informative empty states.
- Plain-language methods, limitations, dynamic denominators and volunteer-sampling language.

## Data and denominator decisions

- Source: the group's `Dataset(1).csv` supplied for the earlier analysis, 112 responses. This copy removes only the course-specific `studentID` field; analytical values are unchanged.
- 110 respondents use AI; 2 non-users skipped usage questions. Skipped responses remain missing, not zero or No.
- Overview tool-choice percentages include all currently filtered respondents. In Figure 1, each purpose's denominator is the AI users with that purpose before the tool filter, after the other sidebar filters. Tool selection changes the numerator and the response tables; Figure 2 uses only the selected eligible respondents.
- Hours were directly entered as numeric weekly coursework hours. Viewing limits zoom the graph; sidebar hours controls filter data.
- Sampling is volunteer/self-selected, **not a probability sample**. Model-based tests do not repair self-selection or guarantee population representativeness.
- The tool-purpose Monte Carlo test retains original categories (`B = 100000`, seed 304). The hours-switching model retains the prior exploratory quadratic logistic specification. Filtering can make a test unavailable; the app then explains why. No Gaussian residual assumption plots are added.
- The current release uses 112 responses. Replace any fixed data-collection wording in `R/study_D.R` if the dataset is updated.

## Categorical filter approved for this group

According to the group's TA correspondence, **Primary AI tool** is an acceptable alternative for this dataset. It is a categorical survey response, not a demographic variable. The shared sidebar selection updates the overview, both figure pages, and the data explorer. Some association tests are unavailable after filtering, such as the tool–purpose test when only one tool remains.

## Publish on Posit Connect Cloud (E)

1. Review the integrated figures and text with B/C/D and verify the shared Primary AI tool filter.
2. In this folder run `source("make_manifest.R")`; rerun it after changing dependencies or application files.
3. Commit the app, `R/`, `www/`, anonymized `data/survey.csv`, generated `manifest.json`, and README to your group's public GitHub repository. The original identifier-containing CSV is not part of this project.
4. In [Posit Connect Cloud](https://connect.posit.cloud), publish **Shiny for R**, select that repository/branch, and select `app.R` as the primary file.
5. Wait for the build, open the public address in a fresh/private browser, and test the filters, both plot pages and the empty-result case.
6. Put the verified public URL at the top of this README and submit the URL as instructed.

This build has not been deployed to Posit. A locally working app is only the starting point for deployment.

Official references: [Shiny modules](https://shiny.posit.co/r/articles/improve/modules/), [Shiny for R deployment](https://docs.posit.co/connect-cloud/how-to/r/shiny-r.html), [dependency manifests](https://docs.posit.co/connect-cloud/how-to/r/dependencies.html). Assignment source: supplied `5-STA304-Website-Instructions-2026.pdf`.
