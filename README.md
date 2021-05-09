# micro-editor_wordCompletion

**word completion plugin for the micro editor**  

This plugin adds a command to execute word completion.  

User can select a candidate from words collected from active buffer.  

## Usage 

1. Move the cursor to the right edge of a half-finished word.
2. Press Ctrl-e, type 'wordCompletion' then Enter.
3.  If there is only one candidate, the rest of the word is immediately filled.  
    
    Otherwise, a pane opens at the bottom and shows indexed candidates.  
    Type one of indexes and Enter.

## Installation

Move 'wordCompletion.lua' file into '~/.config/micro/plug/'  

### Add keybinding (optional) 

Add a keybinding in  '~/.config/micro/bindings.json' as following example.  

Example:  

```json
{
    "~~~~": "~~~~",
    "~~~~": "~~~~",
    "CtrlSpace": "command:wordCompletion"
}
```
