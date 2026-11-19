# You can override some default options with config.fish:
#
#  set -g theme_short_path yes
#  set -g theme_stash_indicator yes
#  set -g theme_ignore_ssh_awareness yes

# This prompt started as the Oh My Fish default theme. Keep the Git helpers
# local so the prompt also works when OMF is not installed.
function git_is_repo
  command git rev-parse --git-dir > /dev/null 2>&1
end

function git_branch_name
  command git symbolic-ref --quiet --short HEAD 2> /dev/null
  or command git rev-parse --short HEAD 2> /dev/null
end

function git_is_stashed
  command git rev-parse --verify --quiet refs/stash > /dev/null
end

function git_is_touched
  set -l git_status (command git status --porcelain --untracked-files=normal 2> /dev/null | string collect)
  test -n "$git_status"
end

function git_ahead
  set -l counts (command git rev-list --left-right --count '@{upstream}...HEAD' 2> /dev/null)

  if test $status -ne 0
    echo -n $argv[4]
    return
  end

  set counts (string split \t -- $counts)
  set -l behind_count $counts[1]
  set -l ahead_count $counts[2]

  if test $ahead_count -gt 0 -a $behind_count -gt 0
    echo -n $argv[3]
  else if test $ahead_count -gt 0
    echo -n $argv[1]
  else if test $behind_count -gt 0
    echo -n $argv[2]
  else
    echo -n $argv[4]
  end
end

function fish_prompt
  set -l last_command_status $status
  set -l cwd (set_color FF8C00)(prompt_pwd)(set_color normal)

  if test "$theme_short_path" = 'yes'
    set cwd (set_color FF8C00)(basename (prompt_pwd))(set_color normal)
  else
    set cwd (set_color FF8C00)(prompt_pwd)(set_color normal)
  end

  set -l fish     "⋊"
  set -l ahead    "↑"
  set -l behind   "↓"
  set -l diverged "⥄"
  set -l dirty    "⨯"
  set -l stash    "≡"
  set -l none     "◦"

  set -l normal_color     (set_color normal)
  set -l success_color    (set_color FF8C00)
  set -l error_color      (set_color $fish_color_error 2> /dev/null; or set_color red --bold)
  set -l directory_color  (set_color $fish_color_quote 2> /dev/null; or set_color brown)
  set -l repository_color (set_color $fish_color_cwd 2> /dev/null; or set_color green)

  set -l prompt_string $fish

  if test "$theme_ignore_ssh_awareness" != 'yes' -a -n "$SSH_CLIENT$SSH_TTY"
    set prompt_string "$fish "(whoami)"@"(hostname -s)" $fish"
  end

  if test $last_command_status -eq 0
    echo -n -s $success_color $prompt_string $normal_color
  else
    echo -n -s $error_color $prompt_string $normal_color
  end

  if git_is_repo
    if test "$theme_short_path" = 'yes'
      set root_folder (command git rev-parse --show-toplevel 2> /dev/null)
      set parent_root_folder (dirname $root_folder)
      set cwd (echo $PWD | sed -e "s|$parent_root_folder/||")
    end

    echo -n -s " " $directory_color $cwd $normal_color
    echo -n -s " on " $repository_color (git_branch_name) $normal_color " "


    set -l list
    if test "$theme_stash_indicator" = yes; and git_is_stashed
      set list $list $stash
    end
    if git_is_touched
      set list $list $dirty
    end
    echo -n $list

    if test -z "$list"
      echo -n -s (git_ahead $ahead $behind $diverged $none)
    end
  else
    echo -n -s " " $directory_color $cwd $normal_color
  end

  echo -n -s " "
end
