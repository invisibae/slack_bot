library(slackr)


test <- "this is a test message"

slackr_setup(txt = this_week_allegations,
             token = Sys.getenv("SLACK_TOKEN"),
             channel = Sys.getenv("SLACK_CHANNEL"),
             username = Sys.getenv("SLACK_USERNAME"),
             icon_emoji = Sys.getenv("SLACK_ICON_EMOJI"),
             thread_ts = NULL,
             reply_broadcast = FALSE
)

slackr_msg(txt = this_week_allegations,
           token = Sys.getenv("SLACK_TOKEN"),
           channel = Sys.getenv("SLACK_CHANNEL"),
           username = Sys.getenv("SLACK_USERNAME"),
           icon_emoji = Sys.getenv("SLACK_ICON_EMOJI"),
           thread_ts = NULL,
           reply_broadcast = FALSE
)

