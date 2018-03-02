### Unreleased

### 0.7.1 - 2018-03-02

#### Fixed:
- Fix to handle empty last_error strings [#40](https://github.com/statianzo/que-web/pull/40)

### 0.7.0 - 2018-02-02
#### Added:
- Delete All and Reschedule All ([#39](https://github.com/statianzo/que-web/pull/39))

#### Docs:
- Upgrade vulnerable rack version in example

### 0.4.0 - 2015-04-09
#### Added:
- Indicate when a job is past due #2

#### Fixed:
- Fix clipping of pagination buttons #11
- Turn time string into time object #13


### 0.3.2 - 2014-12-05
#### Fixed:
- Fix escaping on pagination controls #10

### 0.3.1 - 2014-11-24
#### Fixed:
- Flash messages were not getting swept

### 0.3.0 - 2014-11-24
#### Added:
- Dockerfile #1
- Show errors in list view #7
- Relative "x minutes from now" dates for all visible dates #3
- Display flash messages on delete or run immediate actions (only if session available) #6
- CHANGELOG file

#### Fixed:
- Large argument lists now wrap in list view #8

#### Security:
- Use Erubis to escape html by default #9


### 0.2.2 - 2014-11-14
#### Added:
- Working dashboard
- List running, scheduled, and failing jobs
- Delete jobs
- Run jobs immediately
- Show job details
