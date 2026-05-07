"""
AutoFix AI Simulator — Prototype
Streamlit-based test interface using AWS Bedrock.
Models: Amazon Nova Micro (ultra-cheap) vs Claude Haiku 4.5.
Region: us-east-1.
"""
import json
import streamlit as st
import boto3

from scenarios import get_scenario_by_id, get_scenarios_by_difficulty
from prompts import build_game_system_prompt, build_hint_system_prompt, sanitize_input, validate_output

# --- Constants ---
AWS_REGION = "us-east-1"
MODELS = {
    "Amazon Nova Micro ($0.035/1M) 🏆": "us.amazon.nova-micro-v1:0",
    "Amazon Nova Lite ($0.06/1M)": "us.amazon.nova-lite-v1:0",
    "Claude Haiku 4.5 ($0.80/1M)": "us.anthropic.claude-haiku-4-5-20251001-v1:0",
}
PRICING = {
    "us.amazon.nova-micro-v1:0": {"input": 0.035, "output": 0.14},
    "us.amazon.nova-lite-v1:0": {"input": 0.06, "output": 0.24},
    "us.anthropic.claude-haiku-4-5-20251001-v1:0": {"input": 0.80, "output": 4.00},
}

st.set_page_config(page_title="🔧 AutoFix AI Simulator — Prototype", page_icon="🔧", layout="wide")


@st.cache_resource
def get_bedrock_client():
    return boto3.client("bedrock-runtime", region_name=AWS_REGION)

bedrock = get_bedrock_client()

# --- Session State ---
defaults = {
    "messages": [], "scenario": None, "game_active": False,
    "interaction_count": 0, "hints_used": 0,
    "total_input_tokens": 0, "total_output_tokens": 0,
    "model_choice": list(MODELS.values())[0], "diagnosed": False,
}
for k, v in defaults.items():
    if k not in st.session_state:
        st.session_state[k] = v


def is_nova(model_id: str) -> bool:
    return "nova" in model_id


def call_bedrock(system_prompt: str, messages: list, model_id: str) -> tuple[str, dict]:
    """Call Bedrock — handles both Nova and Claude API formats."""
    if is_nova(model_id):
        # Nova uses Bedrock Converse-style format
        nova_msgs = []
        for m in messages:
            nova_msgs.append({"role": m["role"], "content": [{"text": m["content"]}]})
        body = {
            "system": [{"text": system_prompt}],
            "messages": nova_msgs,
            "inferenceConfig": {"maxTokens": 200},
        }
    else:
        # Claude uses Anthropic Messages API format
        body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 200,
            "system": [{"type": "text", "text": system_prompt, "cache_control": {"type": "ephemeral"}}],
            "messages": messages,
        }

    response = bedrock.invoke_model(
        modelId=model_id, contentType="application/json",
        accept="application/json", body=json.dumps(body),
    )
    result = json.loads(response["body"].read())

    if is_nova(model_id):
        text = result["output"]["message"]["content"][0]["text"]
        usage = result.get("usage", {})
        return text, {"input_tokens": usage.get("inputTokens", 0), "output_tokens": usage.get("outputTokens", 0)}
    else:
        text = result["content"][0]["text"]
        usage = result.get("usage", {})
        return text, {"input_tokens": usage.get("input_tokens", 0), "output_tokens": usage.get("output_tokens", 0)}


def get_total_cost() -> float:
    p = PRICING[st.session_state.model_choice]
    return (
        st.session_state.total_input_tokens * p["input"] / 1e6
        + st.session_state.total_output_tokens * p["output"] / 1e6
    )


def start_game(scenario_id: int):
    st.session_state.scenario = get_scenario_by_id(scenario_id)
    st.session_state.messages = []
    st.session_state.game_active = True
    st.session_state.interaction_count = 0
    st.session_state.hints_used = 0
    st.session_state.total_input_tokens = 0
    st.session_state.total_output_tokens = 0
    st.session_state.diagnosed = False
    st.session_state.pop("show_diagnosis", None)


def reset_game():
    st.session_state.game_active = False
    st.session_state.scenario = None
    st.session_state.messages = []
    st.session_state.diagnosed = False
    st.session_state.pop("show_diagnosis", None)


def update_tokens(usage: dict):
    st.session_state.total_input_tokens += usage["input_tokens"]
    st.session_state.total_output_tokens += usage["output_tokens"]


# ============== SIDEBAR ==============
with st.sidebar:
    st.title("🔧 AutoFix AI Simulator")
    st.caption("AWS Bedrock — us-east-1")
    st.divider()

    st.subheader("🤖 AI Model")
    model_label = st.radio("Select:", list(MODELS.keys()), index=0)
    st.session_state.model_choice = MODELS[model_label]
    st.divider()

    st.subheader("🚗 Select a Case")
    for diff in ["Easy", "Medium", "Hard"]:
        emoji = {"Easy": "🟢", "Medium": "🟡", "Hard": "🔴"}[diff]
        with st.expander(f"{emoji} {diff}"):
            for s in get_scenarios_by_difficulty(diff):
                if st.button(f"#{s['id']}: {s['vehicle'][:28]}...", key=f"b_{s['id']}", use_container_width=True):
                    start_game(s["id"])
                    st.rerun()
    st.divider()

    if st.session_state.game_active:
        st.subheader("💰 Cost")
        cost = get_total_cost()
        c1, c2 = st.columns(2)
        c1.metric("Msgs", st.session_state.interaction_count)
        c2.metric("Hints", st.session_state.hints_used)
        st.metric("Session", f"${cost:.6f}")
        st.caption(f"In: {st.session_state.total_input_tokens} | Out: {st.session_state.total_output_tokens}")

        if st.session_state.interaction_count > 0:
            per_msg = cost / st.session_state.interaction_count
            st.metric("1K DAU/day", f"${per_msg * 20 * 1000:.2f}")

        st.divider()
        if st.button("🔄 End Session", use_container_width=True):
            reset_game()
            st.rerun()

# ============== MAIN ==============
if not st.session_state.game_active:
    st.title("🔧 AutoFix AI Simulator — Prototype")
    st.markdown("""
    ### Prompt Testing Interface — AWS Bedrock
    
    | Model | Input/1M | Output/1M | 1K DAU/day |
    |-------|----------|-----------|-----------|
    | **Amazon Nova Micro** 🏆 | $0.035 | $0.14 | ~$0.56 |
    | Amazon Nova Lite | $0.06 | $0.24 | ~$0.96 |
    | Claude Haiku 4.5 | $0.80 | $4.00 | ~$16.00 |
    
    **How to use:** Pick a model → Select a case → Investigate the car → Replace the faulty part to solve it!
    
    💡 Type repair commands like *"Replace the battery"* or *"Change the spark plug on cylinder 3"*
    
    👈 **Select a case to begin!**
    """)
    st.stop()

# --- Active Game ---
scenario = st.session_state.scenario
h1, h2, h3 = st.columns([3, 1, 1])
with h1:
    st.title(f"🚗 Case #{scenario['id']}")
    st.caption(f"{scenario['vehicle']} | {scenario['difficulty']}")
with h2:
    st.metric("Messages", f"{st.session_state.interaction_count}/25")
with h3:
    mname = [k for k, v in MODELS.items() if v == st.session_state.model_choice][0].split("(")[0].strip()
    st.metric("Model", mname)

st.info(f"🗣️ **Customer:** \"{scenario['complaint']}\"")
st.divider()

# Chat history
for msg in st.session_state.messages:
    if msg["role"] == "user":
        avatar = "💡" if msg.get("is_hint") else "🧑‍🔧"
        text = "*[Hint Request]*" if msg.get("is_hint") else msg["content"]
        st.chat_message("user", avatar=avatar).markdown(text)
    else:
        if msg.get("is_hint"):
            st.chat_message("assistant", avatar="👴").markdown(f"**Consultant:** {msg['content']}")
        else:
            st.chat_message("assistant", avatar="🚗").markdown(msg["content"])

if st.session_state.diagnosed:
    st.success("✅ Case complete! Pick a new case from the sidebar.")
    st.stop()

# Cooldown
if st.session_state.interaction_count >= 25:
    st.warning("⏰ **Cooldown!** 25 messages used. In the real app a 45-min timer starts here.")
    st.stop()

# Hint button
if st.button("💡 Ask Consultant", use_container_width=True):
    hint_prompt = build_hint_system_prompt(scenario)
    hint_msgs = [{"role": m["role"], "content": m["content"]} for m in st.session_state.messages]
    hint_msgs.append({"role": "user", "content": "I'm stuck. Give me a hint."})
    with st.spinner("Consultant thinking..."):
        try:
            text, usage = call_bedrock(hint_prompt, hint_msgs, st.session_state.model_choice)
        except Exception as e:
            text = "Consultant stepped out. Try again."; usage = {"input_tokens": 0, "output_tokens": 0}
            st.error(f"Error: {e}")
    st.session_state.messages.append({"role": "user", "content": "Hint request", "is_hint": True})
    st.session_state.messages.append({"role": "assistant", "content": text, "is_hint": True})
    st.session_state.hints_used += 1
    update_tokens(usage)
    st.rerun()

# Chat input
user_input = st.chat_input("Inspect, test, or repair... (e.g., 'Replace the spark plug on cylinder 3')")
if user_input:
    # === LAYER 1: Input Sanitization ===
    is_safe, checked_input = sanitize_input(user_input)
    if not is_safe:
        st.session_state.messages.append({"role": "user", "content": user_input})
        st.session_state.messages.append({"role": "assistant", "content": checked_input})
        st.session_state.interaction_count += 1
        st.rerun()

    st.session_state.messages.append({"role": "user", "content": user_input})
    system_prompt = build_game_system_prompt(scenario)

    # Memory pruning
    chat_msgs = [m for m in st.session_state.messages if not m.get("is_hint")]
    if len(chat_msgs) > 6:
        api_msgs = [chat_msgs[0]] + chat_msgs[-5:]
    else:
        api_msgs = chat_msgs
    clean = [{"role": m["role"], "content": m["content"]} for m in api_msgs]

    with st.spinner("Working..."):
        try:
            text, usage = call_bedrock(system_prompt, clean, st.session_state.model_choice)
        except Exception as e:
            text = "The garage lights flicker — something went wrong. Try again."
            usage = {"input_tokens": 0, "output_tokens": 0}
            st.error(f"Error: {e}")

    # === LAYER 3: Output Validation ===
    text = validate_output(text, scenario)

    # Check for [CASE_SOLVED] tag
    case_solved = "[CASE_SOLVED]" in text
    clean_text = text.replace("[CASE_SOLVED]", "").strip()

    st.session_state.messages.append({"role": "assistant", "content": clean_text})
    st.session_state.interaction_count += 1
    update_tokens(usage)

    if case_solved:
        st.session_state.diagnosed = True

    st.rerun()

