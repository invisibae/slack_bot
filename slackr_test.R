library(slackr)


test <- "this is a test message"

slackr_setup(
  channel = Sys.getenv("SLACK_CHANNEL"),
  username = Sys.getenv("SLACK_USERNAME"),
  icon_emoji = Sys.getenv("SLACK_ICON_EMOJI"),
  incoming_webhook_url = Sys.getenv("SLACK_INCOMING_WEBHOOK_URL"),
  token = Sys.getenv("SLACK_TOKEN")
)



slackr_msg(txt = this_week_allegations,
           token = Sys.getenv("SLACK_TOKEN"),
           channel = Sys.getenv("SLACK_CHANNEL"),
           username = Sys.getenv("SLACK_USERNAME"),
           icon_emoji = Sys.getenv("SLACK_ICON_EMOJI"),
           thread_ts = NULL,
           reply_broadcast = FALSE
)

