content = File.read(".planning/ROADMAP.md")
updated_content = content.sub("**Plans**: TBD", "**Plans**: 3 plans\n- [ ] 79-01-PLAN.md — Core Configuration & Behaviours\n- [ ] 79-02-PLAN.md — Oban Queue Adapter\n- [ ] 79-03-PLAN.md — S3 Storage Adapter")

if content == updated_content
  puts "No changes made to roadmap"
else
  File.write(".planning/ROADMAP.md", updated_content)
  puts "Roadmap updated"
end
