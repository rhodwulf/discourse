import EmailPreview, { oneWeekAgo } from "admin/models/email-preview";
import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  model() {
    return EmailPreview.findDigest(this.currentUser.username);
  },

  afterModel(model) {
    const controller = this.controllerFor("adminEmailPreviewDigest");
    controller.setProperties({
      model,
      username: this.currentUser.username,
      lastSeen: oneWeekAgo(),
      showHtml: true,
    });
  },
});
