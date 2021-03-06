class Runner < ActiveRecord::Base
  def self.import(file)
    added = 0
    teams = 0
    skipped = 0
    self.clear_existing_data
    CSV.foreach(file.path, headers: true) do |row|
      if row["OE0002"] == "***"
        skipped += 1
      elsif row["Short"].start_with? "I"
        if row["Text1"]
          school = row["Text1"]
        else
          school = "Unknown"
        end
        
        jrotc = nil
        if row['Text3']&.include? "JROTC"
          jrotc = "JROTC"
        end
        
        runner = Runner.create(database_id: row["Stno"],
                      surname: row["Surname"].gsub("'"){"\\'"},
                      firstname: row["First name"].gsub("'"){"\\'"},
                      school: school.gsub("'"){"\\'"},
                      entryclass: row["Short"],
                      jrotc: jrotc,
                      gender: row['S'])
        added += 1
        
        # Runner is created, now check their team information. Attempt
        # to find team and then create it if necessary.
        # Text1 = School Name
        # Text2 = Team Name
        # Text3 = Team Type
        if row['Text2']
          team = nil
          
          # Find Team
          team, created = Team.find_or_create(row)
          if team == nil
            puts "Something bad happened. Team wasn't created."
          end
          
          if created
            teams += 1
          end
          
          TeamMember.create(team_id: team.id,
                            runner_id: runner.id)
        end
      else
        skipped += 1
      end
    end
    [added, skipped]
  end

  def self.import_results_row(row)
    if (row["Time1"])
      res = self.get_float_time(row["Time1"])
      float_time1 = res['float']
      time1 =  res['time']
    else
      float_time1 = 0.0
    end
    if (row["Time2"])
      res = self.get_float_time(row["Time2"])
      float_time2 = res['float']
      time2 =  res['time']
    else
      float_time2 = 0.0
    end
    if (row["Total"])
      res = self.get_float_time(row["Total"])
      float_total = res['float']
      total =  res['time']
    else
      float_total = 0.0
    end
    Runner.where(database_id: row['Stno'].to_s)
      .update_all(time1: time1,
                  float_time1: float_time1,
                  classifier1: row["Classifier1"].to_s,
                  time2: time2,
                  float_time2: float_time2,
                  classifier2: row["Classifier2"].to_s,
                  total_time: total,
                  float_total_time: float_total)

  end

  private

  def self.clear_existing_data
    TeamMember.delete_all
    Team.delete_all
    Day1Awt.delete_all
    Day2Awt.delete_all
    Runner.delete_all
  end

  def self.get_float_time(time)
    float_time = 0.0
    hhmmss = time.split(":")
    if (hhmmss.length ==3 ) then
      time = time
      hh = hhmmss[0].to_i
      mm = hhmmss[1].to_i
      ss = hhmmss[2].to_i
      float_Time = (hh*60) + mm + (ss/60.0)
    elsif (hhmmss.length == 2) then
      time = "00:" + time
      mm = hhmmss[0].to_i
      ss = hhmmss[1].to_i
      float_Time = mm + (ss/60.0)
    end
    {'float' => float_Time, 'time' => time}
  end

end
