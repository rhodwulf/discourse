import UserAction from "discourse/models/user-action";
import UserActivityStreamRoute from "discourse/routes/user-activity-stream";
import I18n from "I18n";
import { action } from "@ember/object";

export default UserActivityStreamRoute.extend({
  userActionType: UserAction.TYPES["posts"],

  emptyState() {
    const user = this.modelFor("user");

    let title, body;
    if (this.isCurrentUser(user)) {
      title = I18n.t("user_activity.no_replies_title");
      body = "";
    } else {
      title = I18n.t("user_activity.no_replies_title_others", {
        username: user.username,
      });
      body = "";
    }

    return { title, body };
  },

  @action
  didTransition() {
    this.controllerFor("application").set("showFooter", true);
    return true;
  },
});
