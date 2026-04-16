# config.nu
#
# Installed by:
# version = "0.109.1"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings,
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

# 단일 라인 프롬프트 (WezTerm 렌더링 밀림 방지)
$env.PROMPT_COMMAND = {|| $"(ansi cyan)(pwd | path basename)(ansi reset)" }
$env.PROMPT_INDICATOR = " > "
$env.PROMPT_COMMAND_RIGHT = ""

# Shell integration 비활성화 (WezTerm 렌더링 충돌 방지)
$env.config = ($env.config | merge {
    shell_integration: {
        osc2: false
        osc7: false
        osc9_9: false
        osc133: false
        osc633: false
        reset_application_mode: false
    }
})
