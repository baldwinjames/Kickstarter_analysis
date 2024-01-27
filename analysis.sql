-- A quick review through the data to get a sense of what's there and to make sure the import worked
SELECT * FROM campaign LIMIT 10;
SELECT * FROM category LIMIT 10;
SELECT * FROM sub_category LIMIT 10;
SELECT * FROM currency LIMIT 10;
SELECT * FROM country LIMIT 10;

-- Since we're reviewing financial data, I'm going to convert everything into USD.
ALTER TABLE currency
ADD COLUMN USD_Conversion NUMERIC;

-- We're only dealing with about a dozens sets of currencies and we're only doing this as a one-off, so no need for dynamic values.
UPDATE currency
SET USD_Conversion = 1.26
WHERE currency.name = 'GBP';

-- A quick double-check to make sure everything works the way I want
SELECT * FROM currency;

-- I realized I can manually set the values in the PostgreSQL output, so the remaining currencies were updated that way

-- Since I'm going to likely run quite a few queries with this data, I'm going to add it to the main campaign table
ALTER TABLE campaign
ADD COLUMN Pledged_USD NUMERIC,
ADD COLUMN Goal_USD NUMERIC;

-- Now to update the new fields with the converted values
UPDATE campaign
SET 
    pledged_usd = pledged * (SELECT usd_conversion FROM currency WHERE currency.id = campaign.currency_id),
    goal_usd = goal * (SELECT usd_conversion FROM currency WHERE currency.id = campaign.currency_id);

-- A final check to make sure it all looks good
SELECT * FROM campaign LIMIT 10;

-- We don't need to be too specific with this analysis, so going to fully round all the currency values
UPDATE campaign
SET
	pledged_usd = ROUND(pledged_usd,0),
	goal_usd = ROUND(goal_usd,0);

-- The data has now been formatted the way I want and can finally be queried. To get a sense of the data to help answer the primary questions, I'm going to look at:
--    Understanding if there's a difference in money raised between successful campaigns and unsuccessful campaigns
--    The top and bottom 3 categories by backers
--    The top and bottom 3 sub-categories by backers
--    The top and bottom 3 categories by money raised
--    The top and bottom 3 sub-categories by money raised
--    Taking a look at which tabletop game raised the most money and checking to see how many backers they had
--    Ranking the top 3 countries with the most successful campaigns in terms of money raised and backers
--    Finally, trying to figure out if the length of a campaign impacts how much money is raised

SELECT outcome, round(avg(pledged_usd),0) AS  "average pledged", round(avg(goal_usd),0) AS "average goal", COUNT(backers) AS total_backers
FROM campaign 
GROUP BY outcome
LIMIT 10;

-- It's clear there's a huge difference in both funds raised and backers but the biggest thing that stands out to me is that successful campaigns tend to have significantly lower goal amounts. 

SELECT "category"."name" AS "Category Name", sum(backers) AS backers
FROM campaign
JOIN "sub_category" ON "sub_category"."id" = "campaign"."sub_category_id"
JOIN "category" ON "category"."id" = "sub_category"."category_id"
GROUP BY "category"."name"
ORDER BY "backers" DESC
LIMIT 3;

SELECT "category"."name" AS "Category Name", sum(backers) AS backers
FROM campaign
JOIN "sub_category" ON "sub_category"."id" = "campaign"."sub_category_id"
JOIN "category" ON "category"."id" = "sub_category"."category_id"
GROUP BY "category"."name"
ORDER BY "backers" ASC
LIMIT 3;

-- Top 3 categories by Backer: Games, Technology, Design
-- Bottom 3 categories by Backer: Dance, Journalism, Crafts

SELECT "sub_category"."name" AS "Sub-Category Name", sum(backers) AS backers
FROM campaign
JOIN "sub_category" ON "sub_category"."id" = "campaign"."sub_category_id"
JOIN "category" ON "category"."id" = "sub_category"."category_id"
GROUP BY "sub_category"."name"
ORDER BY "backers" DESC
LIMIT 3;

SELECT "sub_category"."name" AS "Sub-Category Name", sum(backers) AS backers
FROM campaign
JOIN "sub_category" ON "sub_category"."id" = "campaign"."sub_category_id"
JOIN "category" ON "category"."id" = "sub_category"."category_id"
GROUP BY "sub_category"."name"
ORDER BY "backers" ASC
LIMIT 3;

-- Top 3 sub-categories by backer: Tabletop Games, Product Design, Video Games
-- Bottom 3 sub-categories by backer: Glass, Photo, Latin

SELECT "category"."name" AS "Category Name", SUM("campaign"."pledged_usd") AS "Total Pledged"
FROM "campaign"
JOIN "sub_category" ON "sub_category"."id" = "campaign"."sub_category_id"
JOIN "category" ON "category"."id" = "sub_category"."category_id"
GROUP BY "category"."name"
ORDER BY "Total Pledged" DESC
LIMIT 3; 

SELECT "category"."name" AS "Category Name", SUM("campaign"."pledged_usd") AS "Total Pledged"
FROM "campaign"
JOIN "sub_category" ON "sub_category"."id" = "campaign"."sub_category_id"
JOIN "category" ON "category"."id" = "sub_category"."category_id"
GROUP BY "category"."name"
ORDER BY "Total Pledged" ASC
LIMIT 3; 

-- Top 3 categories by funds raised: Technology, Games, Design
-- Bottom 3 categories by funds raised: Journalism, Dance, Crafts

SELECT "sub_category"."name" AS "SubCategory Name", SUM("campaign"."pledged_usd") AS "Total Pledged"
FROM "campaign"
JOIN "sub_category" ON "sub_category"."id" = "campaign"."sub_category_id"
JOIN "category" ON "category"."id" = "sub_category"."category_id"
GROUP BY "sub_category"."name"
ORDER BY "Total Pledged" DESC
LIMIT 3;

SELECT "sub_category"."name" AS "SubCategory Name", SUM("campaign"."pledged_usd") AS "Total Pledged"
FROM "campaign"
JOIN "sub_category" ON "sub_category"."id" = "campaign"."sub_category_id"
JOIN "category" ON "category"."id" = "sub_category"."category_id"
GROUP BY "sub_category"."name"
ORDER BY "Total Pledged" ASC
LIMIT 3;

-- Top 3 sub-categories by funds raised: Product Design, Tabletop Games, Video Games
-- Bottom 3 sub-categories by funds raised: Glass, Crochet, Latin

-- Overall general observations: These observations make a lot of sense given the general market Kickstarter appeals to and it's a promosing sign that tabletop games
-- our main focus, is quite popular on the platform. Time to look at what is the most successful tabletop game.

SELECT campaign.name, pledged_usd, backers FROM campaign
JOIN sub_category ON sub_category.id = campaign.sub_category_id
JOIN category ON category.id = sub_category.category_id
WHERE sub_category.name = 'Tabletop Games'
ORDER BY pledged_usd DESC
LIMIT 1;

-- Gloomhaven wins by a large margin, raising almost $4m from over 40,000 backers. Let's see if the country data shows anything unusual.

SELECT country.name, round(sum(pledged_usd),0) AS "Total Pledged" FROM campaign
JOIN country ON country.id = campaign.country_id 
GROUP BY country.name 
ORDER BY "Total Pledged" DESC
LIMIT 3;

-- Nope, US, UK, CA are at the top as would be expected. 
-- Upon looking for data for dates, I realized I left that out of the import, so I created a new table with the info and now need to add it into campaigns.

ALTER TABLE campaign
ADD COLUMN launched DATE,
ADD COLUMN deadline DATE;

UPDATE campaign
SET
    launched = dates.launched,
    deadline = dates.deadline
FROM temp_table
WHERE campaign.id = dates.id;

-- I think I want to add two additional fields - one that looks at the length of a campaign and another that buckets those dates.

ALTER TABLE campaign
ADD COLUMN "Campaign Length" INTEGER,
ADD COLUMN "Campaign Bucket" INTEGER;

UPDATE campaign
SET "Campaign Length" = deadline - launched;

UPDATE campaign
SET "Campaign Bucket" = CASE
    WHEN "Campaign Length" <= 14 THEN 'Short'
    WHEN "Campaign Length" BETWEEN 15 AND 30 THEN 'Medium'
    WHEN "Campaign Length" > 30 THEN 'Long'
END;

-- Okay, time to take a look at how much money gets raised by campaign length

SELECT round(sum(pledged_usd),0) AS "Total Pledged", "Campaign Bucket" FROM campaign
GROUP BY "Campaign Bucket"
ORDER BY "Total Pledged" DESC
LIMIT 3;

-- Sure enough, the longer a campaign runs, the more money gets raised. Medium and long term earn far more than shorter campaigns.
