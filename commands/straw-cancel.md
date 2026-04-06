---
description: "Cancel an active Straw loop"
hide-from-slash-command-tool: "true"
---

# Cancel Straw Loop

```!
if [ -f ".straw/plans/ACTIVE" ]; then
  plan=$(cat .straw/plans/ACTIVE | jq -r '.plan // empty' 2>/dev/null || cat .straw/plans/ACTIVE)
  rm -f .straw/plans/ACTIVE
  echo "Straw loop cancelled. Plan was: ${plan}"
else
  echo "No active Straw loop found."
fi
```
