import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# ==========================================
# 1. Configuration & Data Loading
# ==========================================
CSV_FILE = "sample_data/run_standalone_zram_metrics.csv"
ENGINE = "zram" # Set to 'none', 'zram', or 'zswap'
HARDWARE_RAM_MB = 128.0

df = pd.read_csv(CSV_FILE)
df = df.sort_values("timestamp_rel")

# ==========================================
# 2. Data Cleaning & Unit Conversions (MB)
# ==========================================
df['mem_total_mb'] = df['mem_total'] / 1024
df['mem_used_mb'] = df['mem_used'] / 1024
df['mem_free_mb'] = df['mem_free'] / 1024
df['mem_buff_cache_mb'] = df['mem_buff_cache'] / 1024
df['anon_pages_mb'] = df['anon_pages'] / 1024

df['engine_pool_mb'] = df['engine_pool'] / (1024 * 1024)
if ENGINE == "zswap":
    df['engine_stored_mb'] = (df['engine_stored'] * 4096) / (1024 * 1024)
else:
    df['engine_stored_mb'] = df['engine_stored'] / (1024 * 1024)

# ==========================================
# 3. Derived Academic Metrics
# ==========================================
# Compression Ratio (Safe division to avoid zero errors on 'basic' runs)
df['compression_ratio'] = np.where(df['engine_pool_mb'] > 0, df['engine_stored_mb'] / df['engine_pool_mb'], 0)

# Hardware Stack Logic
df['static_overhead_mb'] = HARDWARE_RAM_MB - df['mem_total_mb']
df['static_overhead_mb'] = df['static_overhead_mb'].clip(lower=0)

# Baseline used (subtracting compressed pool so we don't double count it in the stacked chart)
df['mem_used_base_mb'] = df['mem_used_mb'] - df['engine_pool_mb']
df['mem_used_base_mb'] = df['mem_used_base_mb'].clip(lower=0)

# ==========================================
# 4. Generating Publication Plots
# ==========================================
plt.style.use('ggplot')
fig, axes = plt.subplots(3, 1, figsize=(10, 14), sharex=True)
fig.suptitle(f'Standalone ARM64 Bare-Metal Benchmarks ({ENGINE.upper()})', fontsize=16, fontweight='bold')

# --- Plot 1: Memory Pressure ---
ax1 = axes[0]
ax1.set_title("System Memory Pressure", fontsize=12)
ax1.plot(df['timestamp_rel'], df['mem_used_mb'], label="System Used RAM", color="purple", linewidth=2)
ax1.plot(df['timestamp_rel'], df['anon_pages_mb'], label="Browser Payload (AnonPages)", color="darkviolet", linestyle="--")
ax1.plot(df['timestamp_rel'], df['mem_free_mb'], label="System Free RAM", color="green", linewidth=2)
ax1.axhline(y=HARDWARE_RAM_MB, color='red', linestyle='--', label=f"True Physical Limit ({HARDWARE_RAM_MB}MB)")
ax1.set_ylabel("Memory (MB)")
ax1.legend(loc="upper left")

# --- Plot 2: Compression Efficiency ---
ax2 = axes[1]
ax2.set_title("Memory Engine Density", fontsize=12)
if ENGINE != "none":
    ax2.plot(df['timestamp_rel'], df['engine_stored_mb'], label="Uncompressed Payload", color="blue", linestyle='--')
    ax2.plot(df['timestamp_rel'], df['engine_pool_mb'], label="Compressed Pool (RAM Used)", color="blue", linewidth=2)

    ax2_ratio = ax2.twinx()
    ax2_ratio.plot(df['timestamp_rel'], df['compression_ratio'], label="Ratio", color="black", linestyle=':', alpha=0.7)
    ax2_ratio.set_ylabel("Ratio (X:1)")
    ax2_ratio.legend(loc="upper right")
else:
    ax2.text(0.5, 0.5, 'Basic Configuration: No Compression Engine Active',
             horizontalalignment='center', verticalalignment='center', transform=ax2.transAxes, fontsize=12, color='gray')
ax2.set_ylabel("Memory (MB)")
ax2.legend(loc="upper left")

# --- Plot 3: Hardware Physical RAM Stacked Area ---
ax3 = axes[2]
ax3.set_title("True Physical Memory Composition", fontsize=12)

stack_labels = ['Static Boot Overhead', 'Compressed Data (Pool)', 'System Used (Base)', 'Buff/Cache', 'Free RAM']
stack_colors = ['#333333', '#1f77b4', '#7f7f7f', '#ff7f0e', '#2ca02c']

ax3.stackplot(
    df['timestamp_rel'],
    df['static_overhead_mb'],
    df['engine_pool_mb'],
    df['mem_used_base_mb'],
    df['mem_buff_cache_mb'],
    df['mem_free_mb'],
    labels=stack_labels,
    colors=stack_colors,
    alpha=0.85
)
ax3.set_ylabel("Memory (MB)")
ax3.set_xlabel("Time (Seconds)")
ax3.set_ylim(0, HARDWARE_RAM_MB)
ax3.legend(loc="upper left", reverse=True)

plt.tight_layout()
plt.subplots_adjust(top=0.94)
plt.savefig(f"standalone_{ENGINE}_benchmark.png", dpi=300)
plt.show()
