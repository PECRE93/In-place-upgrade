# Security policy

## Supported versions

Security fixes go into the latest release only.

## Reporting a vulnerability

Don't report vulnerabilities in public issues. Use [private vulnerability reporting](https://github.com/PECRE93/In-place-upgrade/security/advisories/new) instead, and include the version, how to reproduce the problem and the impact you expect.

The tool runs elevated on production servers, so these issues matter most:

- anything that makes the tool change a server, or run code from a data file or report;
- a way for someone without administrator rights to influence the result of a check;
- secrets ending up in a report. Reports should hold only an inventory of the server, never credentials.

## Sharing reports

Reports list the services, applications, listening ports and domain membership of a server. Store them like other server documentation, and remove server names, domains and IP addresses before you share one in an issue.
