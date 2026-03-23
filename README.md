# GENCORDIC – Scale-Free Word-Serial CORDIC Core

## Overview
The `GENCORDIC` module is a resource-optimized, parameterizable VHDL implementation of the CORDIC (COordinate Rotation DIgital Computer) algorithm. 

The architecture utilizes an iterative **word-serial approach**. By feeding the data path back through the same hardware arithmetic unit over multiple clock cycles, combinatorial logic (area footprint) is heavily minimized while enabling high clock frequencies. The core is **scale-free**, meaning the inherent CORDIC gain ($A_n \approx 1.64676$) is compensated for internally. No trailing hardware multiplier is required to correct the output magnitude.

## Specifications & Resource Utilization
* **Language:** VHDL-2008 (utilizing `numeric_std` and `signed`)
* **Architecture:** Iterative / Word-Serial (Multi-Cycle)
* **Data Type:** Fixed-point (parameterizable via `DATAWIDTH`)
* **Target Hardware Reference (Xilinx Series-7 (from Spartan-7 upwards!) as 16 Bit Implementation):**
  * **System Clock:** >= 250 MHz
  * **LUTs:** ~500 (at 16-bit data width)
  * **Flip-Flops:** ~270 (at 16-bit data width)

## Interfaces (Ports)

### Configuration (Generics)
| Generic | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `DATAWIDTH` | `natural` | 16 | Bit width of the input and output vectors (`X`, `Y`, `Z`). |

### Signals (Ports)
| Port | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `CLK` | in | 1 | Global system clock. |
| `RESET` | in | 1 | Reset signal. |
| `START` | in | 1 | Start signal (Handshake `VALID`). Triggers the computation on High. |
| `BUSY` | out | 1 | Status signal (Handshake `not READY`). High while the core is iterating. |
| `X_IN`, `Y_IN`, `Z_IN` | in | `DATAWIDTH` | Input data as `signed` vectors. |
| `X_OUT`, `Y_OUT`, `Z_OUT`| out | `DATAWIDTH` | Output data as `signed` vectors. |
| `MU` | in | 2 | Coordinate system: `"01"` (Circular), `"11"` (Hyperbolic), `"00"` (Linear). |
| `MODE` | in | 1 | Operating mode: `'0'` (Rotation), `'1'` (Vectoring). |
| `ITERATIONS` | in | `natural` | Number of iteration steps (defines precision, <span style="color:red">Use a multiple of four (4-32)!!!</span>). |

## Operating Modes (`MU` & `MODE`)

The core supports the three classic CORDIC coordinate systems across two operating modes.

### Rotation Mode (`MODE = '0'`)
Rotates the vector $(x_0, y_0)$ by the given angle $z_0$.
* **Circular (`MU = "01"`):** Computes Sine and Cosine. $x_n = x_0 \cos(z_0) - y_0 \sin(z_0)$
* **Hyperbolic (`MU = "11"`):** Computes Sinh and Cosh.
* **Linear (`MU = "00"`):** Multiplication.

### Vectoring Mode (`MODE = '1'`)
Rotates the vector $(x_0, y_0)$ towards the X-axis ($y_n \rightarrow 0$) to compute the angle and magnitude.
* **Circular (`MU = "01"`):** Cartesian to Polar conversion. $z_n = z_0 + \arctan(y_0 / x_0)$. <span style="color:red">Note alternated Fixed-Point Scaling!!!</span>
* **Hyperbolic (`MU = "11"`):** Computes inverse hyperbolic tangent (arctanh).
* **Linear (`MU = "00"`):** Division.

## Data Type
| Configuration | Fixed-Point Representation | Comment |
| :--- | :--- | :--- |
|`MU = "01"` & `MODE = '1'` | Q4.(`DATAWIDTH`-4) | only for this mode to cover whole $2\pi$ interval |
|all remaining | Q2.(`DATAWIDTH`-2) | |


## Integration & Handshake Protocol

The `GENCORDIC` uses a simple `START` / `BUSY` protocol allowing for synchronization of the processing element with a superior controller/state machine. Because it is a word-serial multi-cycle design, the core cannot accept new data while an iteration is in progress.

**AXI4-Stream Integration:**
To integrate this core into a high-speed pipeline (e.g., 250 MHz), it is highly recommended to wrap the inputs and outputs with an **Elastic Wrapper (Skid Buffer)** to prevent routing delays from causing timing violations.
* Map the upstream `S_AXIS_TVALID` to `START`.
* Invert `BUSY` (`not BUSY`) to drive the upstream `S_AXIS_TREADY`.

---

## Instantiation Template

```vhdl
-- Component Declaration
component GENCORDIC is
    generic(
        DATAWIDTH : natural range 4 to 32 := 16
    );
    port (
        CLK        : in std_logic;
        X_IN       : in signed(DATAWIDTH-1 downto 0);
        Y_IN       : in signed(DATAWIDTH-1 downto 0);
        Z_IN       : in signed(DATAWIDTH-1 downto 0); 
        MU         : in std_logic_vector(1 downto 0);
        MODE       : in std_logic;
        ITERATIONS : in natural range 0 to DATAWIDTH;
        RESET      : in std_logic;
        START      : in std_logic;
        BUSY       : out std_logic;
        X_OUT      : out signed(DATAWIDTH-1 downto 0);
        Y_OUT      : out signed(DATAWIDTH-1 downto 0);
        Z_OUT      : out signed(DATAWIDTH-1 downto 0)  
    );
end component;

-- Port Map
u_GENCORDIC : GENCORDIC
    generic map (
        DATAWIDTH  => 16
    )
    port map (
        CLK        => clk_sig,
        RESET      => reset_sig,
        START      => start_sig,
        BUSY       => busy_sig,
        X_IN       => x_in_sig,
        Y_IN       => y_in_sig,
        Z_IN       => z_in_sig,
        MU         => mu_sig,
        MODE       => mode_sig,
        ITERATIONS => iterations_sig,
        X_OUT      => x_out_sig,
        Y_OUT      => y_out_sig,
        Z_OUT      => z_out_sig
    );
