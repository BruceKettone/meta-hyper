import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# ==========================================
# 1. Configuration & Data Loading
# ==========================================
HOST_CSV = "/content/sample_data/run1_zram_lkvm_metrics.csv"
GUEST_CSV = "/content/sample_data/run1_guest_metrics.csv"
ENGINE = "zram" # Set to 'zswap' or 'zram' to handle byte vs page conversions
HOST_TOTAL_RAM_MB = 128.0 # Your strict physical limit

host_df = pd.read_csv(HOST_CSV)
guest_df = pd.read_csv(GUEST_CSV)

# Sort by timestamp to ensure clean merging
host_df = host_df.sort_values("timestamp_rel")
guest_df = guest_df.sort_values("timestamp_rel")

# Merge the two datasets based on the closest relative timestamp
# This elegantly handles the slight float misalignments between the two bash loops
df = pd.merge_asof(host_df, guest_df, on="timestamp_rel", direction="nearest")

# ==========================================
# 2. Data Cleaning & Unit Conversions (to MB)
# ==========================================
# Convert kilobyte metrics to Megabytes
df['mem_free_mb'] = df['mem_free'] / 1024
df['mem_slab_mb'] = df['mem_slab'] / 1024
df['anon_pages_mb'] = df['anon_pages'] / 1024
df['mem_available_mb'] = df['mem_available'] / 1024

# Engine data conversions (Bytes to MB)
df['engine_pool_mb'] = df['engine_pool'] / (1024 * 1024)

if ENGINE == "zswap":
    # zswap 'stored_pages' is in 4KB pages
    df['engine_stored_mb'] = (df['engine_stored'] * 4096) / (1024 * 1024)
else:
    # zram 'orig_data_size' is already in bytes
    df['engine_stored_mb'] = df['engine_stored'] / (1024 * 1024)

# ==========================================
# 3. Derived Metrics (The Math)
# ==========================================
# Compression Ratio = Original Size / Compressed Pool Size
df['compression_ratio'] = np.where(
    df['engine_pool_mb'] > 0,
    df['engine_stored_mb'] / df['engine_pool_mb'],
    0
)

# Fault Rate
df['pgmajfault_rate'] = df['pgmajfault_x'].diff().fillna(0).clip(lower=0)

# The Stacked Area Math: Calculate unlogged Host overhead
df['host_other_mb'] = HOST_TOTAL_RAM_MB - df['mem_free_mb'] - df['mem_slab_mb'] - df['engine_pool_mb']
df['host_other_mb'] = df['host_other_mb'].clip(lower=0) # Prevent measurement noise from dipping below 0

# ==========================================
# 4. Generating Publication Plots
# ==========================================
plt.style.use('ggplot')
fig, axes = plt.subplots(4, 1, figsize=(10, 18), sharex=True)
fig.suptitle(f'Nested ARM64 Overcommit Benchmarks ({ENGINE.upper()} + lkvm)', fontsize=16, fontweight='bold')

# --- Plot 1: The Overcommit Proof ---
ax1 = axes[0]
ax1.set_title("Memory Pressure & Overcommit Proof", fontsize=12)
ax1.plot(df['timestamp_rel'], df['anon_pages_mb'], label="Guest Payload (AnonPages)", color="purple", linewidth=2)
ax1.plot(df['timestamp_rel'], df['mem_free_mb'], label="Host Free RAM", color="green", linewidth=2)
ax1.axhline(y=HOST_TOTAL_RAM_MB, color='red', linestyle='--', label="Host Physical Limit (150MB)")
ax1.set_ylabel("Memory (MB)")
ax1.legend(loc="upper left")

# --- Plot 2: Compression Efficiency ---
ax2 = axes[1]
ax2.set_title("Memory Engine Density", fontsize=12)
ax2.plot(df['timestamp_rel'], df['engine_stored_mb'], label="Uncompressed Payload", color="blue", linestyle='--')
ax2.plot(df['timestamp_rel'], df['engine_pool_mb'], label="Compressed Pool (RAM Used)", color="blue", linewidth=2)
ax2.set_ylabel("Memory (MB)")

# Add a secondary Y axis for the ratio
ax2_ratio = ax2.twinx()
ax2_ratio.plot(df['timestamp_rel'], df['compression_ratio'], label="Compression Ratio", color="black", linestyle=':', alpha=0.7)
ax2_ratio.set_ylabel("Ratio (X:1)")
ax2.legend(loc="upper left")
ax2_ratio.legend(loc="upper right")

# --- Plot 3: The Thrashing Threshold ---
ax3 = axes[2]
ax3.set_title("Latency & System Stability", fontsize=12)
ax3.plot(df['timestamp_rel'], df['pgmajfault_rate'], label="Host Major Page Faults / sec", color="red", linewidth=2)
ax3.set_ylabel("Faults per second")

# Add a secondary Y axis for OOM Kills
ax3_oom = ax3.twinx()
ax3_oom.plot(df['timestamp_rel'], df['oom_kills'], label="Guest OOM Kills", color="black", linewidth=2, drawstyle='steps-post')
ax3_oom.set_ylabel("OOM Events", color="black")
ax3_oom.set_yticks(range(0, max(int(df['oom_kills'].fillna(0).max()) + 2, 2)))

ax3.legend(loc="upper left")
ax3_oom.legend(loc="upper right")

# --- Plot 4: Host Physical RAM Stacked Area ---
ax4 = axes[3]
ax4.set_title("Host Physical Memory Composition", fontsize=12)

# Define the layers of the stack from bottom to top
stack_labels = ['Compressed Data (Engine Pool)', 'Kernel Overhead (Slab)', 'Host OS & lkvm Base', 'Free RAM']
stack_colors = ['#1f77b4', '#ff7f0e', '#7f7f7f', '#2ca02c']

ax4.stackplot(
    df['timestamp_rel'],
    df['engine_pool_mb'],
    df['mem_slab_mb'],
    df['host_other_mb'],
    df['mem_free_mb'],
    labels=stack_labels,
    colors=stack_colors,
    alpha=0.85
)

ax4.set_ylabel("Memory (MB)")
ax4.set_xlabel("Time (Seconds)")
ax4.set_ylim(0, HOST_TOTAL_RAM_MB)
ax4.legend(loc="upper left", reverse=True) # Reverse legend to match visual stack order

plt.tight_layout()
plt.subplots_adjust(top=0.94)
plt.savefig(f"{ENGINE}_benchmark_stacked.png", dpi=300)
plt.show()
