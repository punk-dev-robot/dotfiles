# Pinned Linear IDs — refresh with the linear_* MCP tools (list_teams, list_users, list_projects, list_initiatives, list_issue_labels, list_issue_statuses, list_cycles). Fetched 2026-09-17.

Workspace: swap-commerce. Access via direct `linear` MCP server (`linear_*` tools), NOT `gateway_linear_*`.

## Me

- Kuba Gaj — `d1db2cbb-cc29-4101-a793-8fa029e3e945` — kuba.gaj@swap-commerce.com
  (verified via `linear_list_users` query "kuba" — single exact match)

## Teams

Team keys resolved from live issue identifiers (`linear_list_issues` with `includeArchived:true`, since `list_teams`/`get_team` do not return the `key` field in this MCP surface).

| key | name | id | squad lead |
|---|---|---|---|
| AGI | Agentic (parent) | `62f87de9-2d7b-401d-8bbd-749477d7a773` | **NEVER CREATE HERE** |
| AGIA | Agentic - Agents | `d807b5cc-2b39-41fd-b229-b5ebeb3eee24` | Denis Sokolov — `743ef528-6e68-4765-8a7e-e42955a08a9f` |
| AGIC | Agentic - Core | `94f3abc3-6249-461a-b55f-496074596205` | Marcel Niebylski — `c6198bc2-8596-4bb3-afd6-8da4816aa5ac` |
| AGIK | Agentic - Checkout | `bb7ecd80-521e-4031-beec-012dd337043f` | Rafael Alencar (**-ext preferred**) — `a19625b8-b52c-41ca-acb5-9f127e9a4d33` (rafael-ext@swap-commerce.com). Non-ext duplicate also exists: `85e5badd-e080-4122-a405-cd6538fbad62` (rafael@swap-commerce.com) |
| AGIF | Agentic - Frontend | `7c78e0a0-70ba-482f-b473-8d9613d0d4a5` | Adriano Cangiamila — `62ad0122-a099-45e6-b957-dffc4fe9c641` |
| AGIP | Agentic - Products | `eadf00ab-977b-44f4-b227-3b7b0493ac3c` | Gabriel Bregadioli Limoni (**-ext preferred**, only account found) — `57c6b1fa-afdc-428c-9967-b6434e6e1692` (gabriel-ext@swap-commerce.com) |
| AGIT | Agentic - Integrations | `7ee37c68-aabc-4e40-a2e5-e6f7f8f544b6` | Mark Gangel — `586703bd-a064-42d1-85ee-461310165a4b` |
| AGIX | Agentic - Delivery | `bf7d40c2-1d10-425b-8d6a-f403c9c191ae` | Gabriel Oliveira — `6de4046c-c2bf-4718-86ee-28d00d64ad2f` |
| AGID | Agentic - Data Science | `12d42540-2aba-4440-ae65-6a493589117a` | Jan Siml — `04909587-85b1-4e38-bf9c-bd68e13dc22c` |
| KUB | Kuba | `693c032d-cf0d-40fc-9673-49f9a5966585` | n/a (private team) |

Note: for "Rafael" the runbook prefers `-ext`; two Rafael accounts exist (`rafael-ext@...` and `rafael@...`) — use the `-ext` id above. For "Gabriel Limoni" only the `-ext` account (`gabriel-ext@swap-commerce.com`) was found; no non-ext duplicate exists.

## Initiatives (active Agentic Q3'26)

| name | id | url |
|---|---|---|
| Agentic - Traffic Acquisition - Q3'26 | `60ceaaca-69b1-44d0-b6ca-c81f87146b1f` | https://linear.app/swap-commerce/initiative/agentic-traffic-acquisition-q326-644e9883be85 |
| Agentic - Onboarding - Q3'26 | `dfb588e2-e9c3-43fa-a80e-dbd88cab4f30` | https://linear.app/swap-commerce/initiative/agentic-onboarding-q326-6d534055626f |
| Agentic - Proprietary agent technology - Q3'26 | `2f2e2210-610e-4ef4-af19-9cbf87ea4b1d` | https://linear.app/swap-commerce/initiative/agentic-proprietary-agent-technology-q326-c6610e2ef62b |
| Agentic - Paul Smith - Q3'26 | `dc970a42-232e-4df7-8716-65836e8e1d4e` | https://linear.app/swap-commerce/initiative/agentic-paul-smith-q326-9e25241cec74 |
| Agentic - Improve base design - Q3'26 | `ad435196-e72a-4711-b0df-43c69f0805ae` | https://linear.app/swap-commerce/initiative/agentic-improve-base-design-q326-2fcfc822ca12 |
| Agentic - BAO - Q3'26 | `a0c9e988-0101-4004-be67-a523a5448398` | https://linear.app/swap-commerce/initiative/agentic-bao-q326-364655d7dd5f |
| Agentic - Reducing custom development - Q3'26 | `b81bae82-3a0a-48cc-a400-2451ca63d1b2` | https://linear.app/swap-commerce/initiative/agentic-reducing-custom-development-q326-12bfae0b2d58 |
| Agentic - Keep the lights on (KTLO) - Q3'26 | `ed92daad-af50-47b9-8200-db507cdc1029` | https://linear.app/swap-commerce/initiative/agentic-keep-the-lights-on-ktlo-q326-87c10e2f8324 |

Note: a second, **Canceled** "Agentic - BAO - Q3'26" duplicate exists (`24316d88-1062-4df5-ad96-67301d140a65`) — do not use, listed for disambiguation only. There is also a non-Agentic "Global Core Q3 KTLO & Technical Improvements" (`9e7c03b4-2bd4-454a-b8df-6badeabb290f`) and "BAU-KTLO Company" (`deb60b70-054f-4ee1-91b2-e86abfccbd16`) — not Agentic-scoped, do not conflate with the KTLO initiative above.

## Projects

### KTLO project (pinned)

| name | id | url |
|---|---|---|
| Agentic - Keep the lights on (KTLO) - Q3'26 | `b83650fc-9fab-42aa-9274-d1eb65fab1b5` | https://linear.app/swap-commerce/project/agentic-keep-the-lights-on-ktlo-q326-31efaf2acb88 |

Lead: Ramiro Valdez. Spans nearly every Agentic subteam plus a few outside teams (Data Science & AI, Agentic Commerce, Returns).

### Other active Agentic projects (state=started, capped at 40 of 58 found)

| name | id | lead | teams |
|---|---|---|---|
| Search-keyed infinite scroll + search result explanations | `820ef873-dbbb-4df7-88b6-b26c94fd7918` | Isaac Sijaranamual | Data Science, Frontend, Agents |
| [Spike] expanding channel to whatsapp | `93a88027-4532-41f1-9c05-da04f4ace526` | Mark Gangel | Integrations |
| Historical financial reports | `ea2edf1e-de08-464f-a288-0030b3b1ad2a` | Rafael Alencar | Checkout |
| Analytics Updates | `f1c86c86-1b9e-4de8-8859-bfbfbfba720d` | Rafael Alencar | Checkout |
| Wolf & Badger ingestion enhancement | `2a703069-2805-4e76-a4be-311150de4b7b` | Sebastian Yanik | Products |
| Analysis: CS topic unresolved Topic Analysis | `d866f77d-7476-431e-a4f4-e6277b01eb61` | John Paton | Data Science |
| Checkout pipeline reliability | `ebdf4bfe-6bc4-4619-a4b3-4accdbf76788` | lucas-ext@swap-commerce.com | Checkout |
| Support custom fonts | `9ec40326-a542-41d4-84b6-37db4e08bfe5` | Adriano Cangiamila | Frontend, Core |
| Wolf & Badger multi-brand agent support | `ff9c8d41-1867-4120-bc8e-073e90361716` | Ramiro Valdez | Data Science, Products |
| [Agent Widget Use Case] Product comparison ping pong | `a2949111-b10a-4b3c-8106-5a5cf3dba027` | Mark Gangel | Integrations, Delivery |
| Widget Sidepanel Welcome Page | `cff8e754-aa8b-4eb2-b392-74ae7c5d1345` | Joseph Leung | Integrations, Delivery |
| Willy Chavarria | `0dbfb131-319e-4534-a1bc-305a883c267e` | Rafael Alencar | Checkout, Products, Agentic |
| Paul Smith Backend Leftovers | `da8e08cb-0841-41b7-9bbf-9eee9c1b0421` | Rafael Alencar | Data Science, Checkout, Agents, Core, Products, Agentic |
| [Agent Widget Use Case] Product Hesitation | `7eb96c07-3c44-4a32-a616-864463e196b1` | Richard Orellana | Integrations, Delivery |
| [Agent Widget Use Case] Sizing Fit suggestion | `30045ccc-32e4-4964-a460-fca37f9a2608` | Joseph Leung | Integrations, Delivery |
| SuperDry - Technical Implementation Research | `b40427b1-8d12-40f4-a4ce-1d4d1c38cedd` | Marcel Niebylski | Core |
| Merchant Dashboard Improvements (Batch 1) | `a1277d79-a745-4729-80e4-7087d91a0fa7` | Yanir Manor | Frontend, Core |
| Grebban Redesign Feature Flag Code Cleanup | `a4e6c1c9-5d7a-4b57-910b-57244ae963c8` | Laurentiu Chisan | Frontend |
| Stripe Integration | `e80bb67c-7192-4c7d-91eb-c29ac1bfba1d` | Rafael Alencar | Frontend, Checkout |
| Product's collection staleness | `ad9bfcfa-c48c-4c01-ad95-613bb9f6adca` | Luis Amancio | Products |
| Making CS agent aware of the discount codes v1.2 | `c67af54f-5ab2-46d3-a353-08109056cd54` | Richard Orellana | Integrations |
| QR Code on Avatar VTO | `19590045-acbc-4e27-8bae-16d39755cca4` | Richard Fischer | Data Science, Delivery, Agentic |
| Platform Agnostic | `6e2db08e-3993-443f-bac3-6dcbb704f99c` | Marcel Niebylski | Checkout, Core, Products |
| AAO: Migrate accepted nudges from classic to playbooks | `cd0cdf72-89ee-434a-90e4-a49e8d6a7cc5` | Jesse Claven | Data Science |
| Design improvements | `f014fa7d-f90c-4883-b872-abb43f6fd4fa` | (none) | Frontend, Agentic |
| AAO: Have 5 playbooks from other users | `f839aa82-f6d1-4646-91b5-df6b1975dd8a` | Jesse Claven | Data Science |
| AAO: Improved actions for playbooks for events | `609735f8-5ed2-4d86-b49b-a8fbb3e56ec7` | Jesse Claven | Data Science, Frontend, Agents |
| Visual Merchandising | `bec42c98-23e4-46fa-9ebb-64ffda97748d` | (none) | Data Science, Frontend, Agents, Core, Products, Delivery, Agentic |
| Lead with Product Imagery (and user onboarding) | `e4a2df0c-c02f-4051-850b-c26e43f24064` | Gavin Alves | Data Science, Agentic |
| VTO-aware agent | `0a4129f0-9df3-4d88-991f-bce0086b279b` | Arman Mann | Data Science, Frontend, Agents, Delivery, Agentic |
| Custom Domain Error Handling Improvements | `0f3dbea2-dd63-4e48-b54b-cf198b42f8c0` | Lubos Vanicek | Frontend, Core |
| Recommendations / personalisation | `f168dbc2-340e-468a-a7f8-3decb5e81b6e` | Sebastian Yanik | Data Science, Frontend, Products, Delivery, Agentic |
| Cross-merchant Data Prevention | `5d2d9985-cf23-4764-a6cc-de3e590af5e1` | Pedro Otávio | Data Science, Core, Agentic |
| Paul Smith: Bestsellers | `17bc6c61-5a4b-466b-847f-dac4e74894f4` | Richard Fischer | Data Science, Agents, Products, Delivery, Agentic |
| Product Catalogue - Phase 1 | `ba667bb9-3367-4b5f-a820-29b743e82bf0` | Gabriel Bregadioli Limoni | Products, Agentic |
| Automated Knowledge Pack Onboarding | `6978a25e-9cf7-42b6-8fdd-915e3a90a9c3` | John Paton | Data Science, Integrations |
| BAO - Onboarding Flow API | `bf8d4799-3199-4e38-8cbe-a320799daa06` | Marcel Niebylski | Core |
| VTO-based retargeting | `fd7c96b7-6222-482f-8ced-084c1d5a99e5` | Yanir Manor | Data Science, Integrations |
| Prompt Bug Bash | `e7933501-5e71-4ae9-9d2f-29072733c3c7` | Denis Sokolov | Data Science, Agentic |
| Looks & Outfits for the Main Platform (phase 1) | `5e932350-900f-4c77-8b74-34a11a431d95` | Lindy Brits | Data Science, Frontend, Agents, Delivery |

18 further active Agentic projects exist beyond this cap (e.g. "Agent interview — MVP + user research", "DS metrics —> BigQuery", "AAO (v0.5): Events for playbooks", "SSE connection replacing websockets", "Latest Shopify API Version Alignment", "Admin Dashboard v0.3 Source-Driven Pack Updates", "Checkout monitoring", "Product ingestion visibility on admin dashboard - V 0.2", "Shopify checkout", "Share & Download VTOs", "Paul Smith - Feedbacks", "Paul Smith - Looks", "PS UK & US Prod Store Onboarding", "Paul Smith Storefront — Frontend", "Agentic Onboarding Week 38", "Migrate CI/CD workflows", "Lightdash operational metrics in Agentic", "Improve Ranger e2e coverage") — re-run `linear_list_projects` per team with `state:"started"` for the full, current list.

## Labels

`linear_list_issue_labels` takes a `name` (near-exact) filter and a `team` filter (UUID/name); it has no free-text `query` param. Labels with `team: null` are **workspace-level** (visible/attachable across all teams); labels with a `team` are **per-team** and exist once per team with a distinct id.

| name | scope | id(s) |
|---|---|---|
| Bug | workspace-level | `6467c1b1-f577-44b8-b7be-eda64e27f32a` |
| Bug Source: PROD | workspace-level | `121e5c61-044f-4874-802c-f1713ae0d279` |
| Bug Source: UAT | workspace-level | `5e507dd1-4bd0-4e70-8849-f5cb6c794a1e` |
| Query | workspace-level | `467b21e6-7b31-441a-9e19-33f61a0d7e0f` |
| `platform: Storefront` (raw name `Storefront`) | per-team, exists on every Agentic subteam + parent | AGI `c0ddc0c5-10ec-42e1-98f7-5544fda6ef5d`; AGIA `a8046f0f-add8-490f-a579-839115d48096`; AGIC `72f2fdc7-15e3-4280-82e0-321be9f426d4`; AGIK `36944889-05b2-4484-b241-1574654dbc04`; AGIF `ebc26da9-1022-410b-b446-d143a65c291d`; AGIP `4eae0b9a-c6d7-4066-a23b-3569304636ba`; AGIT `c0c336a4-7bd4-4589-a13b-916b12ead1a9`; AGIX `69eb6c8d-e042-4b4d-87b4-b488b98345e6`; AGID `21922ac0-162a-40c2-9eb5-2fac88458869` |
| pending-estimation | per-team, exists on every Agentic subteam + parent (also on team "Agentic - Paul Smith Frontend") | AGI `a259045c-e0c7-4cbf-97d7-11b6b27e5e73`; AGIA `25425504-e4ee-4c60-ab2a-90a0b764d061`; AGIC `da517f3f-c714-4ef7-9e71-5dd40f04847c`; AGIK `28c1c911-18ec-4a57-873c-29facd6d09ec`; AGIF `11e8c40a-e6ca-49db-a1f2-802bc2d099c6`; AGIP `fd35d397-2b32-4a2c-af0f-1c8060cab343`; AGIT `72c11967-732c-47f0-a3af-93119af6eceb`; AGIX `dc285bbe-ee62-4df7-ab4b-7d729a10221c`; AGID `8694016f-f487-4235-b103-36f44db1f719` |
| all-brands | per-team, exists on every Agentic subteam + parent (also on team "Agentic - Paul Smith Frontend") | AGI `fb7c70f2-275b-43ce-8f4a-94313b31d3de`; AGIA `71c39832-ad4a-4059-bac2-5d5d9d9f6292`; AGIC `345fe66f-c4cd-4d74-bb9a-c85779811738`; AGIK `2d94e606-5fe0-4a59-864d-4b2fe38f66ab`; AGIF `f392a298-5601-476f-ad96-366fafa4883e`; AGIP `6c81570c-694f-4a3b-9fdd-b89edc06e68a`; AGIT `93223054-a05e-44fc-b59c-bbb7d0136da0`; AGIX `ae56f86f-f6a8-4e54-a9e2-9f29c5a43a2f`; AGID `2eef5c38-9f4f-442d-8121-c759b2135d2a` |
| `wayfinder:*` | per-team; canonical home is team **Kuba** (private team per conventions), but the same four names also exist as separate per-team labels on "Global - Core" — not shared ids, just parallel names | Kuba: `wayfinder:map` `16afd485-091b-4ce6-be00-351c178e0246`; `wayfinder:task` `6e0f0167-78c7-4027-95e6-7efd4c6e5f4a`; `wayfinder:research` `5a167a9d-ad0e-441c-8209-40d0e9ca1d43`; `wayfinder:grilling` `7e22ef6d-c7e8-4a91-a8b9-a32fded5b726` |
| eleven-loves | **not found** | — |
| manors | **not found** | — |
| re-test | **not found** | — |

See "Gaps" below for the three labels not found.

## Statuses

### Agentic - Checkout (AGIK)

| name | type | id |
|---|---|---|
| Triage | triage | `1a619601-9278-416c-bb09-64bd79acff8f` |
| Backlog - General | backlog | `fd462cca-e13c-4d9c-9345-6b7c1a965ba9` |
| Todo | unstarted | `86819082-32c7-4d8f-a3a2-2f140640a232` |
| In Progress | started | `13fc8302-771c-4650-828d-a7e87607f4d9` |
| On Hold | started | `349dfdfe-677f-4a69-9b97-95da00946a53` |
| In Review | started | `5912264a-a915-4a59-b1b8-2b15257f937d` |
| DEV | completed | `d718b522-f1ff-46f3-bdc9-b4ac22b38048` |
| QA | completed | `57a67c17-c03e-4dae-8633-82a50ed9d5dd` |
| UAT | completed | `0b9a3938-902c-4ed8-a0ae-cb35f6454a07` |
| Done | completed | `4e4c33c3-396a-48eb-8cd0-1825e1544892` |
| Duplicate | duplicate | `58ceb3e6-058d-44c4-8966-65e2ec48917a` |
| Canceled | canceled | `3132ddeb-6efa-4742-b25f-3fb6b96d3653` |

### Team Kuba

| name | type | id |
|---|---|---|
| Backlog | backlog | `28c03856-4a95-4017-a1eb-96e531bd009e` |
| Todo | unstarted | `167414bd-9462-4616-9b59-aa1b6226b10f` |
| In Progress | started | `ebb36b83-ffc8-41ff-9964-a435f86fe79c` |
| In Review | started | `29d59d83-fbf9-4b97-b866-6c6d834bb91d` |
| Done | completed | `5be6e1da-2bd1-4e63-a99e-0feb559fbcb9` |
| Duplicate | duplicate | `421d3a07-1a7a-45cb-bab3-88333eca5ce3` |
| Canceled | canceled | `72403c94-68d8-4723-9043-c4d2ce85327c` |

## Cycles

**Cycle ids are short-lived — do not treat the ids below as durable pins.** Always re-fetch with `linear_list_cycles({ teamId, type: "current" })` for the live current cycle; the snapshot below (captured 2026-09-17, cycle ends 2026-09-21) is a dated example only, illustrating the shared-vs-per-team behavior:

- Agentic - Checkout (AGIK): "Cycle 38", number 7, id `3823c29e-a38e-45d9-a767-c04f6cae2aeb`, 2026-09-14 → 2026-09-21 (as of fetch date).
- Agentic - Core (AGIC): "Cycle 38", number 7, id `06ab7bf6-612c-4417-8076-d230ceffb04d`, 2026-09-14 → 2026-09-21 (as of fetch date).

**Durable fact:** same title/number and identical date window, but **different cycle ids** per team — cycles are **not shared** across Agentic subteams; each subteam runs its own cycle record even though naming/dates are synchronized.

## Estimate scale

Per runbook: 1 / 3 / 5 / 8 (no fetch needed — not a live Linear value).

## MCP quirks (learned)

- `linear_list_cycles` takes `teamId` (not `team`).
- `linear_save_project`: teams via `addTeams`/`setTeams`, lead via `lead`, initiatives via `addInitiatives`; no `teamIds`/`leadId`.
- `linear_get_issue` does not echo cycle or blocking relations, and can return a **stale state** right after an update — verify state via `linear_list_issues` (`status` field), cycle/blocking in UI.
- `linear_get_project` takes `query` (not `id`). `linear_save_project` patch ops use `text` (not `content`); to append to Decisions-so-far chronologically use `insert_before` anchor `## Not yet specified`.
- `mcpScript` has no `require`/fs — long comment bodies must be inlined (read the file in bash first).
- Workspace-level label `Research` (capital R) exists; per-team `spike`/`decision`/`task` created on AGIA 2026-09-17 (`8a2d8d7a…`, `b930214d…`, `3cd70021…`). AGIA also has `Monitoring and Alerting`.
- Current cycle AGIA at pin time: Cycle 38 `66b3e8ca-a88e-4586-a409-bcc281dd21bb` (2026-09-14→21) — rolls weekly.

## Gaps

- `linear_get_team` / `linear_list_teams` do not expose a `key` field in this MCP server version — team keys above were reverse-derived from live issue identifiers (`linear_list_issues` with `includeArchived:true`) rather than fetched directly as a `key` property.
- Labels `eleven-loves`, `manors`, and `re-test` were not found anywhere in the workspace, including with `includeArchived: true` passed to `linear_list_issue_labels` both workspace-wide (team:null) and per team across all ~40 teams (all Agentic subteams, Kuba, and ~30 other teams including "Agentic - Paul Smith Frontend" which holds many brand-codename labels). They do not currently exist under these exact substrings, active or archived — needs owner confirmation on whether they were renamed, never created, or live in a workspace this MCP connection cannot see.
- The "other active Agentic projects" table is capped at 40 rows per the brief; 18 additional active projects exist and are named (not tabulated) above the cap.
