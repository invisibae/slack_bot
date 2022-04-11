
After a few weeks of working on the bot, I don’t feel like I’ve accomplished all I would’ve liked to, but I have a sense for what I’d like to do to make this an actual usable resource rather than essentially a scraper that also writes posts.

My process for creating the bot was simple enough.  Draw on an extant scraper and use its contents to fuel a bot that would post news of unfair labor practice allegations.  More broadly, from the start of this project we set out to create bots that would alert us to news.  But the overlong wall of text my bot currently produces forces me to reevaluate what constitutes useful news.  

My bot runs (or should run) from two github action workflows, [one running an R script that scrapes and cleans the data](https://github.com/invisibae/slack_bot/blob/main/.github/workflows/r_nlrb_bot.yml), the other [a Python script that filters for allegations made within the last day and posts the contents of the complaint as well as a link to the case on NLRB’s website](https://github.com/invisibae/slack_bot/blob/main/.github/workflows/python_nlrb.yml).  

The process of scaping, cleaning, and posting is made easy by the fact that the data is already [readily available and updates every day](https://github.com/labordata/nlrb-data).  However, the results are, for me, inadequate.  

I’ve come to the conclusion that my bot is hurt primarily by the lack of context that it provides.  As currently constructed, it would take either a bit of prior knowledge of each case or a broad understanding of labor dispute trends to be able to draw any useful conclusions from a daily labor bot update.

Essentially, a daily update gives the user a starting point to start doing reporting, which makes it _decent_ as an internal tool, but it still leaves the reporter with a lot of work to do to answer questions that could be answered automatically by the data.  I need to be able to give context as well as just a daily rundown of what happened for the bot to be effective.  

My biggest issue (and actually the reason why the bot doesn’t actually run) is currently file storage.  The NLRB data is stored in a massive sql database, that in order for each git action to run, must be present in my repository.  This has introduced problems with github lfs.   

I feel like I have already laid the groundwork to create a strong bot.  I have access to data that could put each allegation into proper context (it’s very easy to imagine a few lines of R could that could include some information on how many allegations have been made against this workplace in the past) and my workflows should work once I learn how to use lfs correctly.  

I think this is worth spending some more time this semester refining into something that can actually be useful.  
