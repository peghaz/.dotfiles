# ~/.config/omf/key_bindings.fish

# Vi mode without visible [I]/[N] prompt indicators.
fish_vi_key_bindings

# History search with arrow keys.
bind \e\[A up-or-search
bind \e\[B down-or-search

bind -M insert \e\[A up-or-search
bind -M insert \e\[B down-or-search
