---
name: playwright-ui-validation
description: Reusable workflow for validating rendered operational and data-product surfaces with Playwright after backend changes.
---

# Dotfiles Playwright UI Validation

Reusable workflow for validating rendered operational and data-product surfaces with Playwright after backend changes.

## When to Use

- Validating Grafana dashboards after datasource, query, or provisioning changes
- Validating Streamlit pages, labs, or internal apps backed by live data
- Checking admin or ops panels where backend success is not enough
- Closing a feature that depends on evidence from the rendered UI

## Why This Skill Exists

Backend validation can still miss real failures:

- the page loads but panels show `No data`
- the datasource is provisioned but credentials are empty
- a variable has no default selection
- the query works manually but the dashboard wiring is wrong
- the app route exists but the expected cards, tables, or tabs never render

Use this skill to distinguish:

- backend/data success
- rendered-surface success

Do not treat those as the same thing.

## Prerequisites

- The target service is running and reachable
- You know the URL to validate
- You know at least one concrete piece of data that should appear
  - run id
  - card label
  - panel title
  - KPI value
  - table row
- If auth is required, you have non-secret access to the credentials or session path

## Validation Workflow

### 1. Confirm backend truth first

Before opening the UI, verify the expected data exists:

- database row exists
- API response returns data
- datasource/query works
- run/artifact was persisted

This gives you a reference for what the UI should show.

### 2. Open the real rendered surface

Use Playwright to open the actual page, not a mocked or static artifact.

Prefer checks that answer:

- did the route load?
- did the expected title/header render?
- did the expected run id or entity appear?
- are the important panels/cards/tables populated?
- is the page empty because the state is truly empty, or because the config is broken?

### 3. Assert populated state, not just load success

A successful check should go beyond `200 OK` or `page loaded`.

Look for:

- specific visible text
- expected cards
- populated tables
- non-empty panel states
- correct tab or filter selection
- evidence that a real run/entity is present

If the page loads but everything is empty, treat that as a failure until explained.

### 4. Capture evidence

Always keep evidence for closure:

- screenshot of the rendered page
- URL used
- selected filter/run id
- exact assertions checked
- any API/query verification that supports the UI finding

### 5. Explain failures by layer

If the UI is wrong, classify the problem:

- backend/data problem
- datasource credential/config problem
- dashboard variable/filter problem
- UI rendering/state problem
- expected-empty state

This keeps fixes focused.

## Grafana Validation Pattern

Use this when validating a dashboard:

1. Verify the backing datasource exists and can execute the expected query.
2. Open the dashboard route with any required variables in the URL.
3. Wait for the dashboard to settle.
4. Check:
   - dashboard title
   - selected variable or run id
   - expected panel titles
   - expected text/table content
   - whether key panels are populated or show `No data`
5. Capture a screenshot.

Common Grafana failure patterns:

- datasource provisioned without credentials
- query variable exists but has no initial selection
- time window hides valid data
- panel query is correct in SQL but broken in datasource wiring
- plugin error blocks part of the dashboard even though the page shell loads

## Streamlit Validation Pattern

Use this when validating a Streamlit app or lab:

1. Open the root app.
2. Navigate to the target page if it is a multipage app.
3. Wait for the page to render fully.
4. Check:
   - page title/header
   - expected cards/metrics
   - expected tabs or tables
   - expected run/entity text
   - that the page is populated, not just reachable
5. Capture a screenshot.

Common Streamlit failure patterns:

- page route exists but target page was not selected
- service/backend error is swallowed into a generic empty state
- the page renders shell content but not the data-dependent sections
- backend query changed shape and the UI silently drops content

## Evidence Checklist

- target URL
- service state or health check
- backend truth check performed
- rendered assertions performed
- screenshot captured
- failure layer classified if something is wrong

## Reporting Template

Use a compact closure note:

- surface validated
- URL/route used
- backend fact checked
- rendered elements confirmed
- screenshot path or artifact location
- remaining gap, if any

Example:

- Grafana dashboard validated at `<url>`
- verified datasource query returned run `<run-id>`
- confirmed dashboard title, selected run, populated KPI panels, and summary table
- screenshot captured at `<path>`
- no rendered-state regressions found

## Guardrails

- Do not assume backend success implies UI success
- Do not close a UI-backed task without rendered evidence
- Do not hardcode project-specific secrets or paths into the skill
- Keep assertions tied to stable visible signals, not brittle DOM trivia
