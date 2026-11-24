---
name: vhdl-style
description: >
  Use when writing, editing, or reviewing VHDL in this house style. Enforces
  two-process state machines (a *_fsm process that only changes state with
  case/when, and a *_clock process that acts on state with if statements) and
  one dedicated conditional statement per signal. Trigger on any VHDL change,
  new entity or architecture, FSM, process, or refactor.
---

# VHDL house style

Apply these rules to every VHDL file you write or modify. They are mandatory,
not suggestions. Restyling must not change behavior.

## 1. State machines: exactly two processes

Every FSM is split into `<name>_fsm` and `<name>_clock`:

- `<name>_fsm` is the state register. It assigns **only** the state signal and
  uses `case state_s is ... when ... => ... end case`. No datapath assignments
  and no `if`-only state logic here.
- `<name>_clock` is the datapath. It acts on the current state with
  `if state_s = ... then` blocks. **No `case ... when`** here.

Reset follows the same split: the state signal resets in `_fsm`, every other
signal resets in `_clock`.

```vhdl
  fsm : process (clk_i, rst_ni) is
  begin
    if rst_ni = '0' then
      state_s <= IDLE;
    elsif rising_edge(clk_i) then
      case state_s is

        when IDLE =>
          if start_i = '1' then
            state_s <= BUSY;
          end if;

        when BUSY =>
          if done_s = '1' then
            state_s <= IDLE;
          end if;

      end case;
    end if;
  end process fsm;

  clock : process (clk_i, rst_ni) is
  begin
    if rst_ni = '0' then
      cnt_s  <= (others => '0');
      data_s <= (others => '0');
    elsif rising_edge(clk_i) then

      if state_s = BUSY then
        cnt_s <= cnt_s + 1;
      end if;

      if state_s = IDLE and start_i = '1' then
        data_s <= input_i;
      end if;
    end if;
  end process clock;
```

Use `null;` for a state with no outgoing transition.

## 2. One dedicated statement per signal

In every clocked process, each signal and each port gets its **own** complex
statement: a single `if ... elsif ... end if` chain (or a `case` for the state
signal) containing all of that signal's assignments. Do not assign several
unrelated signals inside one branch.

```vhdl
-- WRONG: one condition drives several unrelated signals
if a_s = '1' then
  b_s <= x;
  c_s <= y;
  d_s <= z;
end if;

-- RIGHT: each signal has its own statement
if a_s = '1' then
  b_s <= x;
end if;

if a_s = '1' then
  c_s <= y;
end if;

d_s <= z;
if e_s = '1' then
  d_s <= w;
end if;
```

Signals with **identical** conditions may share one statement:

```vhdl
if sel_s = '1' then
  data_s  <= data_a_s;
  valid_s <= '1';
elsif ready_i = '1' then
  data_s <= data_b_s;
end if;
```

Default-then-override is a plain assignment followed by its own `if`:

```vhdl
req_s <= '0';
if fire_s = '1' then
  req_s <= '1';
end if;
```

Reset is the only exception: the reset branch may assign every signal at once.

Concurrent assignments (`sig_s <= ...;`) are already one statement each; keep
them that way.

## 3. Naming and layout

- Entity names `CamelCase`; architectures `rtl` (or `behavioral` when required).
- Signals `snake_case_s`; inputs `_i`, outputs `_o`, active-low `_ni` / `_no`.
- Generics `_G`; constants `SCREAMING_SNAKE_C`.
- State types `<name>_state_t` or `fsm_t`; states `ST_*` or uppercase.
- Two-space indentation; align `<=` within a group.
- Put helper functions in the declarative part of the process that uses them.
- Use the project's existing libraries (`ieee.std_logic_1164`,
  `ieee.std_logic_arith`, `ieee.std_logic_unsigned`), not `numeric_std`.
- Add parens around if and elsif conditions.

## 4. Refactoring rules

- Do not change behavior while restyling. Split processes first, then check
  that every condition and priority is preserved.
- Preserve `if` / `elsif` priority when converting a multi-signal block into
  per-signal statements. Event-versus-clear order matters.
- Keep comments that explain intent; move them next to the signal they describe.
