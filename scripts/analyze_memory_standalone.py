import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# ==========================================
# 1. Configuration & Data Loading
# ==========================================
CSV_FILE = "sample_data/run1_zram_metrics.csv"
ENGINE = "zram"
RAM_PHYSICAL_MB = 128

df = pd.read_csv(CSV_FILE)
df = df.sort_values("timestamp_rel")

# ==========================================
# 2. Data Cleaning & Unit Conversions (MB)
# ==========================================
# Guest Metrics
df['mem_total_mb'] = df['mem_total'] / 1024
df['mem_used_mb'] = df['mem_used'] / 1024
df['mem_free_mb'] = df['mem_free'] / 1024
df['mem_buff_cache_mb'] = df['mem_buff_cache'] / 1024

# Anonymous pages (reported in KB in /proc/meminfo)
df['anon_pages_mb'] = df['anon_pages'] / 1024

# Engine conversions
df['engine_pool_mb'] = df['engine_pool'] / (1024 * 1024)
if ENGINE == "zswap":
    df['engine_stored_mb'] = (df['engine_stored'] * 4096) / (1024 * 1024)
else:
    df['engine_stored_mb'] = df['engine_stored'] / (1024 * 1024)

# ==========================================
# 3. Derived Analytical Metrics
# ==========================================
# Meaningful Data: Active Resident Anon Pages + Swapped Anon Pages
df['meaningful_data_mb'] = df['anon_pages_mb'] + df['engine_stored_mb']

# Compression Ratio
df['compression_ratio'] = np.where(df['engine_pool_mb'] > 0, df['engine_stored_mb'] / df['engine_pool_mb'], 0)

# Physical RAM Stack Calculation
# OS Overhead (Hidden memory reserved at boot)
df['os_overhead_mb'] = (RAM_PHYSICAL_MB - df['mem_total_mb']).clip(lower=0)

# The kernel's 'used' metric includes the compressed swap pool.
# We isolate all uncompressed RAM used by processes and kernel structures combined.
df['uncompressed_used_mb'] = (df['mem_used_mb'] - df['engine_pool_mb']).clip(lower=0)


# ==========================================
# 4. Generating Publication Plots
# ==========================================
plt.style.use('ggplot')
fig, axes = plt.subplots(3, 1, figsize=(10, 14), sharex=True)
fig.suptitle(f'STANDALONE {ENGINE.upper()} MEMORY BENCHMARK', fontsize=16, fontweight='bold')

# --- Plot 1: Meaningful Data Limit ---
ax1 = axes[0]
ax1.set_title("Meaningful Data vs Physical Constraints", fontsize=12)

ax1.plot(df['timestamp_rel'], df['meaningful_data_mb'], label="Meaningful Data (Resident + Swapped)", color="purple", linewidth=2)
ax1.axhline(y=RAM_PHYSICAL_MB, color='red', linestyle='--', label=f"Physical Limit ({RAM_PHYSICAL_MB}MB)")

ax1.set_ylabel("Memory (MB)")
ax1.legend(loc="upper left")

# --- Plot 2: Compression Efficiency ---
ax2 = axes[1]
ax2.set_title("Memory Compression", fontsize=12)
ax2.plot(df['timestamp_rel'], df['engine_stored_mb'], label="Uncompressed Payload", color="blue", linestyle='--')
ax2.plot(df['timestamp_rel'], df['engine_pool_mb'], label="Compressed Payload (RAM Used)", color="blue", linewidth=2)
ax2.set_ylabel("Memory (MB)")

ax2_ratio = ax2.twinx()
ax2_ratio.plot(df['timestamp_rel'], df['compression_ratio'], label="Ratio", color="black", linestyle=':', alpha=0.7)
ax2_ratio.set_ylabel("Ratio (X:1)")

ax2.legend(loc="upper left")
ax2_ratio.legend(loc="upper right")

# --- Plot 3: Physical RAM Analysis ---
ax3 = axes[2]
ax3.set_title("Physical RAM Stack Analysis", fontsize=12)

stack_labels = ['OS Overhead (Hidden)', 'File Buff/Cache', 'Compressed Data', 'Uncompressed RAM Used', 'Free RAM']
stack_colors = ['#cb42f5', '#f2f542', '#42aaf5', '#f58a42', '#42f545']

ax3.stackplot(
    df['timestamp_rel'],
    df['os_overhead_mb'],
    df['mem_buff_cache_mb'],
    df['engine_pool_mb'],
    df['uncompressed_used_mb'],
    df['mem_free_mb'],
    labels=stack_labels,
    colors=stack_colors,
    alpha=0.85
)

ax3.set_ylabel("Physical RAM (MB)")
ax3.set_xlabel("Time (Seconds)")
ax3.set_ylim(0, RAM_PHYSICAL_MB)
ax3.legend(loc="upper left", reverse=True)

plt.tight_layout()
plt.subplots_adjust(top=0.94)
plt.savefig(f"standalone_{ENGINE}_benchmark_final.png", dpi=300)
print(f"Graph generated successfully: standalone_{ENGINE}_benchmark_final.png")
# plt.show() # Uncomment to view interactively
