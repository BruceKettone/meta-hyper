import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# ==========================================
# 1. Configuration & Data Loading
# ==========================================
HOST_CSV = "sample_data/host_metrics_idle.csv"
GUEST_CSV = "sample_data/guest_metrics_idle.csv"
ENGINE = "zram"
RAM_HOST_MB = 128
RAM_GUEST_MB = 300

host_df = pd.read_csv(HOST_CSV)
guest_df = pd.read_csv(GUEST_CSV)

host_df = host_df.sort_values("timestamp_rel")
guest_df = guest_df.sort_values("timestamp_rel")
df = pd.merge_asof(host_df, guest_df, on="timestamp_rel", direction="nearest")

# ==========================================
# 2. Data Cleaning & Unit Conversions (MB)
# ==========================================
# Host Metrics
df['host_total_mb'] = df['host_total'] / 1024
df['host_used_mb'] = df['host_used'] / 1024
df['host_free_mb'] = df['host_free'] / 1024
df['host_buff_cache_mb'] = df['host_buff_cache'] / 1024

# Hypervisor's process Metrics
df['hyp_base_mb'] = df['hyp_rss'] / 1024
df['hyp_tot_mb'] = df[' hyp_tot'] / 1024

# Guest Metrics
df['guest_total_mb'] = df['guest_total'] / 1024
df['guest_used_mb'] = df['guest_used'] / 1024
df['guest_free_mb'] = df['guest_free'] / 1024
df['guest_buff_cache_mb'] = df['guest_buff_cache'] / 1024

# Engine conversions
df['engine_pool_mb'] = df['engine_pool'] / (1024 * 1024)
if ENGINE == "zswap":
    df['engine_stored_mb'] = (df['engine_stored'] * 4096) / (1024 * 1024)
else:
    df['engine_stored_mb'] = df['engine_stored'] / (1024 * 1024)

# ==========================================
# 3. Derived Academic Metrics
# ==========================================
# Compression Ratio
df['compression_ratio'] = np.where(df['engine_pool_mb'] > 0, df['engine_stored_mb'] / df['engine_pool_mb'], 0)

# Host Physical Stack Base
df['host_used_base_mb'] = df['host_used_mb'] - df['engine_pool_mb']
df['host_used_base_mb'] = df['host_used_base_mb'].clip(lower=0)
df['host_uncompressed_hypervisor_mb'] = df['hyp_base_mb']
df['host_uncompressed_other_mb'] = df['host_used_base_mb'] - df['host_uncompressed_hypervisor_mb']
df['host_base_os_overhead_mb'] = RAM_HOST_MB - df['host_total_mb']
df['host_base_os_overhead_mb'] = df['host_base_os_overhead_mb'].clip(lower=0)

# Guest Hypervisor Total Overhead
df['guest_used_base_hypervisor_mb'] = df['hyp_tot_mb'] - RAM_GUEST_MB
df['guest_base_os_overhead_mb'] = RAM_GUEST_MB - df['guest_total_mb']

# ==========================================
# 4. Generating Publication Plots
# ==========================================
plt.style.use('ggplot')
fig, axes = plt.subplots(4, 1, figsize=(10, 18), sharex=True)
fig.suptitle(f'LOW FOOTPRINT VIRTUALIZATION BENCHMARK', fontsize=16, fontweight='bold')

# --- Plot 1: Overcommit ---
ax1 = axes[0]
ax1.set_title("Memory Overcommit", fontsize=12)

ax1.plot(df['timestamp_rel'], df['guest_used_mb'], label="Guest Used RAM", color="purple", linewidth=2)

ax1.axhline(y=RAM_HOST_MB, color='red', linestyle='--', label=f"Host Limit ({RAM_HOST_MB:.0f}MB)")
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

# --- Plot 3: Host RAM Analysis ---
ax3 = axes[2]
ax3.set_title("Host RAM Analysis", fontsize=12)

host_stack_labels = ['OS Overhead (Hidden)', 'Host Buff/Cache', 'Compressed Data', 'Other Uncompressed Used', 'Guest+Hypervisor Uncompressed Used', 'Host Free RAM']
host_stack_colors = ['#cb42f5', '#f2f542', '#42aaf5', '#f58a42', '#f54242', '#42f545']

ax3.stackplot(
    df['timestamp_rel'],
    df['host_base_os_overhead_mb'],
    df['host_buff_cache_mb'],
    df['engine_pool_mb'],
    df['host_uncompressed_other_mb'],
    df['host_uncompressed_hypervisor_mb'],
    df['host_free_mb'],
    labels=host_stack_labels,
    colors=host_stack_colors,
    alpha=0.85
)
ax3.set_ylabel("Memory (MB)")
ax3.set_ylim(0, RAM_HOST_MB)
ax3.legend(loc="upper left", reverse=True)

# --- Plot 4: Guest RAM Analysis ---
ax4 = axes[3]
ax4.set_title("Hypervisor Process Analysis", fontsize=12)

guest_stack_labels = ['Hypervisor Overhead', 'Guest OS Overhead (Hidden)', 'Guest Buff/Cache', 'Guest Used', 'Guest Free']
guest_stack_colors = ['#f54299', '#cb42f5', '#f2f542', '#f54242', '#42f545']

ax4.stackplot(
    df['timestamp_rel'],
    df['guest_used_base_hypervisor_mb'],
    df['guest_base_os_overhead_mb'],
    df['guest_buff_cache_mb'],
    df['guest_used_mb'],
    df['guest_free_mb'],
    labels=guest_stack_labels,
    colors=guest_stack_colors,
    alpha=0.85
)
ax4.set_ylabel("Logical Mem (MB)")
ax4.set_xlabel("Time (Seconds)")
ax4.legend(loc="upper left", reverse=True)

plt.tight_layout()
plt.subplots_adjust(top=0.94)
plt.savefig(f"{ENGINE}_benchmark_stacked_final.png", dpi=300)
plt.show()
