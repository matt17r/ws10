badge_families = [
  {
    family: "centurion",
    repeatable: true,
    levels: [
      { level: "bronze", name: "Centurion (Bronze)", slug: "centurion-bronze", description: "Ran 100km at WS10" },
      { level: "silver", name: "Centurion (Silver)", slug: "centurion-silver", description: "Ran 200km at WS10" },
      { level: "gold", name: "Centurion (Gold)", slug: "centurion-gold", description: "Ran 400km at WS10" }
    ]
  },
  {
    family: "traveller",
    repeatable: true,
    levels: [
      { level: "bronze", name: "Traveller (Bronze)", slug: "traveller-bronze", description: "Attended every location once (run or volunteer)" },
      { level: "silver", name: "Traveller (Silver)", slug: "traveller-silver", description: "Attended every location twice (run or volunteer)" },
      { level: "gold", name: "Traveller (Gold)", slug: "traveller-gold", description: "Attended every location four times (run or volunteer)" }
    ]
  },
  {
    family: "consistent",
    repeatable: true,
    levels: [
      { level: "bronze", name: "Consistent (Bronze)", slug: "consistent-bronze", description: "Attended 3 consecutive events (run or volunteer)" },
      { level: "silver", name: "Consistent (Silver)", slug: "consistent-silver", description: "Attended 5 consecutive events (run or volunteer)" },
      { level: "gold", name: "Consistent (Gold)", slug: "consistent-gold", description: "Attended 8 consecutive events (run or volunteer)" }
    ]
  },
  {
    family: "simply-the-best",
    repeatable: true,
    levels: [
      { level: "bronze", name: "Simply the Best (Bronze)", slug: "simply-the-best-bronze", description: "Achieved a personal best (doesn't include your first event)" },
      { level: "silver", name: "Simply the Best (Silver)", slug: "simply-the-best-silver", description: "Achieved 3 personal bests (doesn't include your first event)" },
      { level: "gold", name: "Simply the Best (Gold)", slug: "simply-the-best-gold", description: "Achieved 6 personal bests (doesn't include your first event)" }
    ]
  },
  {
    family: "heart-of-gold",
    repeatable: true,
    levels: [
      { level: "bronze", name: "Heart of Gold (Bronze)", slug: "heart-of-gold-bronze", description: "Volunteered at an event" },
      { level: "silver", name: "Heart of Gold (Silver)", slug: "heart-of-gold-silver", description: "Volunteered at 3 events" },
      { level: "gold", name: "Heart of Gold (Gold)", slug: "heart-of-gold-gold", description: "Volunteered at 6 events" }
    ]
  },
  {
    family: "founding-member",
    repeatable: false,
    levels: [
      { level: "singular", name: "Founding Member", slug: "founding-member", description: "Attended the first ever WS10" }
    ]
  },
  {
    family: "monthly",
    repeatable: true,
    levels: [
      { level: "singular", name: "Monthly", slug: "monthly", description: "Attended an event in every month of the year (can be across multiple years)" }
    ]
  },
  {
    family: "all-seasons",
    repeatable: true,
    levels: [
      { level: "singular", name: "All Seasons", slug: "all-seasons", description: "Attended an event in every season in a calendar year (Summer: Jan-Feb or Dec, Autumn: Mar-May, Winter: Jun-Aug, Spring: Sep-Nov)" }
    ]
  },
  {
    family: "palindrome",
    repeatable: true,
    levels: [
      { level: "singular", name: "Palindrome", slug: "palindrome", description: "Finished with a time where the digits read the same forwards as backwards (e.g. 52:25 or 1:07:01)" }
    ]
  },
  {
    family: "perfect-10",
    repeatable: true,
    levels: [
      { level: "singular", name: "Perfect 10", slug: "perfect-10", description: "Got all the finish positions from 0 to 9 (only the last digit counts, you can collect 4 by coming 4th or 54th)" }
    ]
  }
]

Badge.where.not(slug: badge_families.flat_map { |f| f[:levels].map { |l| l[:slug] } }).destroy_all

badge_families.each do |family_data|
  family_data[:levels].each_with_index do |level_data, index|
    badge = Badge.find_or_initialize_by(slug: level_data[:slug])
    badge.name = level_data[:name]
    badge.description = level_data[:description]
    badge.badge_family = family_data[:family]
    badge.level = level_data[:level]
    badge.level_order = index + 1
    badge.repeatable = family_data[:repeatable]
    badge.save!
  end
end
