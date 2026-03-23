#!/bin/bash

# ─────────────────────────────────────────────────────────────────
# CloudWatch Integration: Logging Setup Script
#
# This script demonstrates the redirection pattern your mentor taught:
# bash /workingdir/scripts/start-cob.sh > /workingdir/logs/start-cob.log 2>&1
#
# Key components:
#   >           = Capture normal output (stdout)
#   2>&1        = Also capture errors (stderr)
#   Together    = Everything goes to the same log file
# ─────────────────────────────────────────────────────────────────

set -e

# Configuration
LOG_DIR="/var/log/cicd-demo"
APP_LOG="$LOG_DIR/app.log"
ERROR_LOG="$LOG_DIR/errors.log"
WORKING_DIR="${1:-.}"

echo "═══════════════════════════════════════════════════════════════"
echo "CloudWatch Logging Setup"
echo "═══════════════════════════════════════════════════════════════"

# Step 1: Create log directories
echo "[1/3] Creating log directories..."
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"
echo "      ✓ Created: $LOG_DIR"

# Step 2: Show redirection explanation
echo ""
echo "[2/3] Understanding Log Redirection:"
echo "      ─────────────────────────────"
echo "      Command: java -jar app.jar > app.log 2>&1"
echo ""
echo "      Breakdown:"
echo "        java -jar app.jar     = Run the application"
echo "        >                     = Redirect normal output (stdout)"
echo "        app.log               = Save to this file"
echo "        2                     = Error stream (stderr)"
echo "        &1                    = Points to stdout (same as normal output)"
echo "        2>&1                  = Send errors to same place as normal output"
echo ""
echo "      Result: Both normal output AND errors go to app.log"
echo ""

# Step 3: Demonstrate redirection in action
echo "[3/3] Testing log redirection..."
echo ""

# Example 1: Successful command with output
echo "      Test 1: Normal operation"
echo "      $ echo 'Application started' >> $APP_LOG 2>&1"
echo 'Application started at '$(date)'' >> "$APP_LOG" 2>&1
echo "      ✓ Logged to: $APP_LOG"
echo ""

# Example 2: Error handling
echo "      Test 2: Error handling"
echo "      $ non_existent_command >> $APP_LOG 2>&1"
{
  non_existent_command 2>&1 || echo "ERROR: Command failed (this is captured)" >> "$APP_LOG" 2>&1
}
echo "      ✓ Error logged to: $APP_LOG"
echo ""

# Show what was logged
echo "═══════════════════════════════════════════════════════════════"
echo "Log File Contents:"
echo "═══════════════════════════════════════════════════════════════"
cat "$APP_LOG"
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "Next Steps:"
echo "─────────────────────────────────────────────────────────────"
echo "1. When you deploy to ECS, the task definition sends logs to CloudWatch"
echo "2. Your Java app produces stdout → automatically captured"
echo "3. ECS LogConfiguration sends it to CloudWatch Logs"
echo "4. Use CloudWatch Log Insights to query both Blue & Green logs"
echo ""
echo "In your ECS Task Definition:"
echo "  LogConfiguration:"
echo "    LogDriver: awslogs"
echo "    Options:"
echo "      awslogs-group: /ecs/cicd-demo"
echo "      awslogs-region: us-east-1"
echo "      awslogs-stream-prefix: ecs"
echo ""
echo "This logs ALL container output to CloudWatch automatically!"
echo "═══════════════════════════════════════════════════════════════"
