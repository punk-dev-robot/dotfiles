---
title: 'ADR-001: MCP Tool Selection Decision'
type: decision
permalink: decisions/adr-001-mcp-tool-selection-decision
---

# ADR-001: MCP Tool Selection Decision

## Key Observations
<!-- These will be extracted as observations -->
- [decision] Chose custom YAML-based MCP configuration over MCPM for native 1Password and dotfiles integration
- [architecture] Implemented profile-based system (shared/trint/personal) with automatic backup and command substitution support
- [outcome] Successfully deployed and operational, providing zero configuration duplication across Claude clients
- [insight] Trade-off accepted: manual server discovery vs. complete integration with existing workflow and security

## Status
**ACCEPTED** - Custom YAML-based solution implemented
Tags: #final #implemented

## Context
Need for centralized MCP server configuration management across Claude Desktop, Claude Code, and future MCP clients (OpenWebUI, etc.) while maintaining security and integration with existing dotfiles workflow.
Tags: #problem #configuration

## Decision
Implement custom YAML-based MCP configuration system instead of adopting existing solutions like MCPM.
Tags: #selected #architecture

## Rationale

### Evaluated Alternatives
- **MCPM (mcpm.sh)** - CLI package manager with router functionality
- **ToolHive** - Enterprise containerized solution
- **MCPJungle** - Self-hosted registry with proxy
- **Custom YAML Solution** - Tailored integration approach ✓

### Decision Factors

#### Why Custom Solution Over MCPM
| Criterion | Custom YAML | MCPM | Weight | Winner |
|-----------|-------------|------|---------|---------|
| **1Password Integration** | ✅ Native | ⚠️ Limited | High | Custom |
| **Dotfiles Integration** | ✅ Native | ⚠️ External | High | Custom |
| **Simplicity** | ✅ No daemon | ⚠️ Router process | Medium | Custom |
| **Command Substitution** | ✅ Any CLI tool | ❌ Limited | Medium | Custom |
| **Backup System** | ✅ Automatic | ❌ Manual | Medium | Custom |
| **Registry Discovery** | ❌ Manual | ✅ Built-in | Low | MCPM |

### Implementation Benefits
- **Security**: All secrets in 1Password, none in repository
- **Integration**: Native dotfiles deployment via Dotter
- **Flexibility**: Support for any CLI tool in command substitution
- **Reliability**: Automatic backup before configuration changes
- **Maintenance**: YAML with comments for easy server management

Tags: #security #integration #extensibility #safety #usability

## Implementation

### Architecture
- **Script**: `local/bin/mcp-config` (bash + jq/yq)
- **Profiles**: `mcp/profiles/*.yaml` (shared, trint, personal)
- **Security**: 1Password CLI integration with `!op read` syntax
- **Deployment**: Updates both Claude Desktop and Code configs

Tags: #core #configuration #secrets #targets

### Usage Pattern
```bash
mcp-config work          # shared + trint profiles
mcp-config personal      # shared + personal profiles  
mcp-config all          # all three profiles
mcp-config --dry-run work # preview without applying
```

## Consequences

### Positive
- ✅ **Zero configuration duplication** across Claude clients
- ✅ **Centralized secret management** with enterprise-grade 1Password
- ✅ **Profile-based organization** for different contexts
- ✅ **Native dotfiles integration** with version control
- ✅ **Automatic backup and restore** capabilities
- ✅ **Comment support** in YAML for documentation

Tags: #efficiency #security #flexibility #integration #safety #maintainability

### Negative
- ❌ **Manual server discovery** (no registry integration)
- ❌ **Limited to Claude clients** initially (vs MCPM's broader support)
- ❌ **Custom maintenance** burden vs community-maintained MCPM

Tags: #limitation #scope #effort

### Risks and Mitigations
- **Risk**: Custom solution maintenance overhead
  - **Mitigation**: Simple bash/jq implementation, well-documented
- **Risk**: Missing new MCP developments
  - **Mitigation**: Regular evaluation of MCPM and alternatives

Tags: #maintenance #simplicity #evolution #monitoring

## Future Considerations

### Potential Migration Triggers
- Multi-client support needs beyond Claude ecosystem
- Registry discovery becomes critical for server management
- Community standardization around MCPM router pattern
- Enterprise requirements for ToolHive-style containerization

Tags: #expansion #discovery #standards #security

### Evolution Path
- **Phase 1**: Current YAML-based solution ✅
- **Phase 2**: MCPO integration for OpenWebUI support 🔄
- **Phase 3**: Potential MCPM migration if benefits justify change
- **Phase 4**: Enterprise evaluation of ToolHive for work environments

Tags: #completed #planned #future #enterprise

## Related Documentation

### Implementation Details
- **Architecture**: `memory://architecture/mcp-configuration-architecture`
- **Setup Guide**: `memory://guides/claude-configuration-setup`
- **Research**: `memory://research/mcp-configuration-research`

### Usage Guides  
- **Setup Instructions**: `memory://guides/setup-guide`
- **Best Practices**: `memory://patterns/migration-best-practices-and-lessons-learned`

Tags: #implementation #guide #background #setup #patterns

## Decision Date
- 2025-06-13 (Initial evaluation)
- 2025-06-17 (Implementation completed)

Tags: #started #completed

## Participants
- Individual developer (personal dotfiles project)
- Based on community research and documentation analysis

Tags: #role #input

---

**Result**: Custom YAML-based solution successfully implemented and operational, providing secure, integrated MCP configuration management within dotfiles workflow.
Tags: #success