class CreatesApplicationFromDraft
  STUDENT_FIELDS = [0, 1].map { |index| User.columns.map(&:name).select{ |n| /\Aapplication_/ =~ n }.map{|n| "student#{index}_#{n}" } }.flatten

  delegate :team, to: :application_draft

  attr_reader :application_draft

  def initialize(application_draft)
    @application_draft = application_draft
  end

  def save
    application.save
  end

  def application
    @application ||= Application.new(application_attributes)
  end

  def application_attributes
    {
      team: team,
      team_snapshot: team_snapshot,
      application_draft: application_draft,
      application_data: application_data,
      season: application_draft.season,
    }
  end

  private

  def application_data
    {
      voluntary: application_draft.voluntary?,
      voluntary_hours_per_week: application_draft.voluntary_hours_per_week,
      heard_about_it: application_draft.heard_about_it,
      misc_info: application_draft.misc_info,
      working_together: application_draft.working_together,
      why_selected_project: application_draft.why_selected_project
    }.merge(student_attributes).merge(project_attributes)
  end

  def project_attributes
    %w(project1_id project2_id project_plan).each_with_object({}) do |attribute, hash|
      hash[attribute] = application_draft.send(attribute)
    end
  end

  def student_attributes
    STUDENT_FIELDS.each_with_object({}) do |attribute, hash|
      hash[attribute] = application_draft.send(attribute)
    end
  end

  class TeamSnapshot < Struct.new(:team)
    def to_hash
      %w(students coaches mentors).each_with_object({}) do |list, hash|
        hash[list] = team.send(list).map { |u| [u.name, u.email] }
      end
    end
  end

  def team_snapshot
    TeamSnapshot.new(team || Team.new).to_hash
  end
end
