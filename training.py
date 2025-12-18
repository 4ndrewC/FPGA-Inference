import numpy as np
import torch
import torch.nn as nn

# ----------------- Training setup -----------------
torch.manual_seed(0)
np.random.seed(0)

def f(x):
    return np.sin(x)

# Training data
N = 1024
x = np.random.uniform(0.0, 2*np.pi, N)
y = f(x)

x_train = torch.tensor(x, dtype=torch.float32).reshape(-1, 1)
y_train = torch.tensor(y, dtype=torch.float32).reshape(-1, 1)


hidden_size = 6

model = nn.Sequential(
    nn.Linear(1, hidden_size),
    nn.ReLU(),
    nn.Linear(hidden_size, hidden_size),
    nn.ReLU(),
    nn.Linear(hidden_size, 1)
)

loss_function = nn.MSELoss()
optimizer = torch.optim.Adam(model.parameters(), lr=0.001)

# Train
epochs = 20000
for epoch in range(epochs):
    optimizer.zero_grad()
    preds = model(x_train)
    loss = loss_function(preds, y_train)
    loss.backward()
    optimizer.step()

    if (epoch + 1) % 2000 == 0:
        print(f"epoch {epoch+1}: MSE = {loss.item():.6f}")

# ----------------- Extract trained weights -----------------
# PyTorch Linear: weight.shape = (out_features, in_features)
# Indices adjust based on model definition: 0=Lin, 1=ReLU, 2=Lin, 3=ReLU, 4=Lin
W0 = model[0].weight.detach().cpu().numpy()  # (10, 1)
b0 = model[0].bias.detach().cpu().numpy()    # (10,)
W1 = model[2].weight.detach().cpu().numpy()  # (10, 10)
b1 = model[2].bias.detach().cpu().numpy()    # (10,)
W2 = model[4].weight.detach().cpu().numpy()  # (1, 10)
b2 = model[4].bias.detach().cpu().numpy()    # (1,)

# ----------------- Q5.11 quantization -----------------
# Q5.11: 1 sign bit, 4 integer bits, 11 fractional bits
# Scale factor = 2^11 = 2048
FRAC_BITS = 11
SCALE = 1 << FRAC_BITS
INT16_MIN, INT16_MAX = -32768, 32767

def quantize_q5_11(x: np.ndarray) -> np.ndarray:
    q = np.rint(x * SCALE).astype(np.int64)
    q = np.clip(q, INT16_MIN, INT16_MAX).astype(np.int16)
    return q

l1weights_q = quantize_q5_11(W0).flatten() # Flatten (10,1) -> (10)
l1bias_q    = quantize_q5_11(b0)
l2weights_q = quantize_q5_11(W1)           # Keep as (10,10)
l2bias_q    = quantize_q5_11(b1)
l3weights_q = quantize_q5_11(W2).flatten() # Flatten (1,10) -> (10)
outbias_q   = quantize_q5_11(b2)           # Scalar

# ----------------- SystemVerilog Formatting -----------------
print("\n// ===== SystemVerilog Output =====\n")

# 1. l1weights (Vertical list, 1 per line)
print(f"logic [15:0] l1weights [{len(l1weights_q)}] = '{{")
for i, val in enumerate(l1weights_q):
    comma = "," if i < len(l1weights_q) - 1 else ""
    print(f"  {val:5d}{comma}")
print("};\n")

# 2. l1bias (8 per line)
print(f"logic [15:0] l1bias [{len(l1bias_q)}] = '{{")
for i in range(0, len(l1bias_q), 8):
    chunk = l1bias_q[i:i+8]
    line_str = ", ".join(f"{v:5d}" for v in chunk)
    suffix = "," if (i + 8) < len(l1bias_q) else ""
    print(f"  {line_str}{suffix}")
print("};\n")

# 3. l2weights (2D Matrix)
rows, cols = l2weights_q.shape
print(f"logic [15:0] l2weights [{rows}][{cols}] = '{{")
for r in range(rows):
    line_vals = ", ".join(f"{v:5d}" for v in l2weights_q[r])
    comma = "," if r < rows - 1 else ""
    print(f"  '{{ {line_vals} }}{comma}")
print("};\n")

# 4. l2bias (8 per line)
print(f"logic [15:0] l2bias [{len(l2bias_q)}] = '{{")
for i in range(0, len(l2bias_q), 8):
    chunk = l2bias_q[i:i+8]
    line_str = ", ".join(f"{v:5d}" for v in chunk)
    suffix = "," if (i + 8) < len(l2bias_q) else ""
    print(f"  {line_str}{suffix}")
print("};\n")

# 5. l3weights (8 per line)
print(f"logic [15:0] l3weights [{len(l3weights_q)}] = '{{")
for i in range(0, len(l3weights_q), 8):
    chunk = l3weights_q[i:i+8]
    line_str = ", ".join(f"{v:5d}" for v in chunk)
    suffix = "," if (i + 8) < len(l3weights_q) else ""
    print(f"  {line_str}{suffix}")
print("};\n")

# 6. outbias (Scalar)
print(f"logic [15:0] outbias = {outbias_q[0]};")

# Test the model with a new input
x_test = torch.tensor([0.4], dtype=torch.float32).reshape(-1, 1)  # Example input
pred_test = model(x_test)  # Get prediction from the trained model

# Print the prediction
print(f"Prediction for input {x_test.item()}: {pred_test.item():.6f}")
