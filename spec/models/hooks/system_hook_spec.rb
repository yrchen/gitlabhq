# == Schema Information
#
# Table name: web_hooks
#
#  id                    :integer          not null, primary key
#  url                   :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  type                  :string(255)      default("ProjectHook")
#  service_id            :integer
#  push_events           :boolean          default(TRUE), not null
#  issues_events         :boolean          default(FALSE), not null
#  merge_requests_events :boolean          default(FALSE), not null
#  tag_push_events       :boolean          default(FALSE)
#

require "spec_helper"

describe SystemHook do
  describe "execute" do
    before(:each) do
      @system_hook = create(:system_hook)
      WebMock.stub_request(:post, @system_hook.url)
    end

    it "project_create hook" do
      Projects::CreateService.new(create(:user), name: 'empty').execute
      expect(WebMock).to have_requested(:post, @system_hook.url).with(body: /project_create/).once
    end

    it "project_destroy hook" do
      user = create(:user)
      project = create(:empty_project, namespace: user.namespace)
      Projects::DestroyService.new(project, user, {}).execute
      expect(WebMock).to have_requested(:post, @system_hook.url).with(body: /project_destroy/).once
    end

    it "user_create hook" do
      create(:user)
      expect(WebMock).to have_requested(:post, @system_hook.url).with(body: /user_create/).once
    end

    it "user_destroy hook" do
      user = create(:user)
      user.destroy
      expect(WebMock).to have_requested(:post, @system_hook.url).with(body: /user_destroy/).once
    end

    it "project_create hook" do
      user = create(:user)
      project = create(:project)
      project.team << [user, :master]
      expect(WebMock).to have_requested(:post, @system_hook.url).with(body: /user_add_to_team/).once
    end

    it "project_destroy hook" do
      user = create(:user)
      project = create(:project)
      project.team << [user, :master]
      project.project_members.destroy_all
      expect(WebMock).to have_requested(:post, @system_hook.url).with(body: /user_remove_from_team/).once
    end

    it 'group create hook' do
      create(:group)
      expect(WebMock).to have_requested(:post, @system_hook.url).with(
        body: /group_create/
      ).once
    end

    it 'group destroy hook' do
      group = create(:group)
      group.destroy
      expect(WebMock).to have_requested(:post, @system_hook.url).with(
        body: /group_destroy/
      ).once
    end

    it 'group member create hook' do
      group = create(:group)
      user = create(:user)
      group.add_user(user, Gitlab::Access::MASTER)
      expect(WebMock).to have_requested(:post, @system_hook.url).with(
        body: /user_add_to_group/
      ).once
    end

    it 'group member destroy hook' do
      group = create(:group)
      user = create(:user)
      group.add_user(user, Gitlab::Access::MASTER)
      group.group_members.destroy_all
      expect(WebMock).to have_requested(:post, @system_hook.url).with(
        body: /user_remove_from_group/
      ).once
    end

  end
end
