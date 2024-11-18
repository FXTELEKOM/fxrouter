from rich.console import Console, Group
from rich.panel import Panel
import json

with open('/tmp/fxdata.json', 'r') as file:
    data = json.load(file)
for key, value in data.items():
    globals()[key] = value

console = Console()
width = 40

def get_static_info():
    text = f"""
DNS IP: {DNS_IP}
HOST IP: {HOST_IP}
VPN IP: {VPN_IP}
        """

    return Panel(
        text.strip(),
        title=f"FXrouter {VERSION}",
        border_style="bold white",
        width=width,
        padding=(0, 1)
    )

if __name__ == "__main__":
    console.print(get_static_info())
