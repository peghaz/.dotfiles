# ~/.config/omf/before.init.fish

# -----------------------------
# Core environment
# -----------------------------

set -gx EDITOR nvim
set -gx VISUAL nvim

set -gx CUDA_HOME /usr/local/cuda
set -gx TENSORRT_ROOT /usr/local/TensorRT

set -gx VCPKG_ROOT $HOME/vcpkg


# -----------------------------
# PATH
# -----------------------------
# fish_add_path is safe in config files: it only adds paths if needed.
# Non-existing paths are ignored.

fish_add_path -m $HOME/.local/bin
fish_add_path -m /usr/local/cuda/bin
fish_add_path -m /usr/local/go/bin
fish_add_path -m /usr/local/TensorRT/bin
fish_add_path -m $VCPKG_ROOT
fish_add_path -m /opt/nvim-linux-x86_64/bin


# -----------------------------
# LD_LIBRARY_PATH
# -----------------------------
# Fish treats PATH-like exported variables as lists internally and exports
# them colon-separated, so this is cleaner than manually writing ":" strings.

set -l ld_paths

for p in /usr/local/TensorRT/lib /usr/local/cuda/lib64
    if test -d $p
        set -a ld_paths $p
    end
end

for p in $LD_LIBRARY_PATH
    if test -n "$p"
        if not contains -- $p $ld_paths
            set -a ld_paths $p
        end
    end
end

if test (count $ld_paths) -gt 0
    set -gx LD_LIBRARY_PATH $ld_paths
end
