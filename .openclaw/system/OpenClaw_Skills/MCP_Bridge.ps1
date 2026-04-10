# OPENCLAW SKILL: MCP BRIDGE [V1.0]
# [OBJECTIVE]: Standardize tool context via Model Context Protocol (MCP).
# [SPEC]: Implementation of tool definitions compatible with Anthropic/Gemini MCP.

$BridgeDir = Join-Path $PSScriptRoot "../skills_bridge"
$RegistryPath = Join-Path $BridgeDir "mcp_registry.json"

function Get-OClawTools {
    $Tools = @(
        @{
            name = "read_file"
            description = "Reads the content of a local project file."
            parameters = @{
                type = "object"
                properties = @{ path = @{ type = "string"; description = "Absolute path to the file." } }
                required = @("path")
            }
        },
        @{
            name = "write_file"
            description = "Writes content to a local project file (Sovereign approval active)."
            parameters = @{
                type = "object"
                properties = @{ 
                    path = @{ type = "string"; description = "Absolute path." }
                    content = @{ type = "string"; description = "Content to write." } 
                }
                required = @("path", "content")
            }
        },
        @{
            name = "web_search"
            description = "Performs a local SearXNG search for high-fidelity research."
            parameters = @{
                type = "object"
                properties = @{ query = @{ type = "string"; description = "Search query." } }
                required = @("query")
            }
        },
        @{
            name = "architect_draft"
            description = "Saves a structural code draft for Gemma-4 architectural review."
            parameters = @{
                type = "object"
                properties = @{ draft_content = @{ type = "string"; description = "The draft code." } }
                required = @("draft_content")
            }
        }
    )
    return $Tools
}

Write-Host "[MCP_BRIDGE] Synchronizing Tool Registry..." -ForegroundColor Magenta

$Tools = Get-OClawTools
$ToolDefinitions = @{
    version = "1.0"
    server = "OpenClaw_Sovereign_Server"
    tools = $Tools
}

$ToolDefinitions | ConvertTo-Json -Depth 10 | Set-Content -Path $RegistryPath -Force

Write-Host "[SUCCESS] MCP Registry Updated. Sovereign tools mapped to global standards." -ForegroundColor Green

return $ToolDefinitions | ConvertTo-Json -Depth 10
