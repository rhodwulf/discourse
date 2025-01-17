import UserMenuItemsList from "discourse/components/user-menu/items-list";
import I18n from "I18n";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { postRNWebviewMessage } from "discourse/lib/utilities";
import showModal from "discourse/lib/show-modal";

export default class UserMenuNotificationsList extends UserMenuItemsList {
  get filterByTypes() {
    return null;
  }

  get showAllHref() {
    return `${this.currentUser.path}/notifications`;
  }

  get showAllTitle() {
    return I18n.t("user_menu.view_all_notifications");
  }

  get showDismiss() {
    return this.items.some((item) => !item.read);
  }

  get dismissTitle() {
    return I18n.t("user.dismiss_notifications_tooltip");
  }

  get itemsCacheKey() {
    let key = "recent-notifications";
    const types = this.filterByTypes;
    if (types?.length > 0) {
      key += `-type-${types.join(",")}`;
    }
    return key;
  }

  get emptyStateComponent() {
    if (this.constructor === UserMenuNotificationsList) {
      return "user-menu/notifications-list-empty-state";
    } else {
      return super.emptyStateComponent;
    }
  }

  fetchItems() {
    const params = {
      limit: 30,
      recent: true,
      bump_last_seen_reviewable: true,
      silent: this.currentUser.enforcedSecondFactor,
    };

    const types = this.filterByTypes;
    if (types?.length > 0) {
      params.filter_by_types = types.join(",");
      params.silent = true;
    }
    return this.store
      .findStale("notification", params)
      .refresh()
      .then((c) => c.content);
  }

  dismissWarningModal() {
    if (this.currentUser.unread_high_priority_notifications > 0) {
      const modalController = showModal("dismiss-notification-confirmation");
      modalController.set(
        "count",
        this.currentUser.unread_high_priority_notifications
      );
      return modalController;
    }
  }

  @action
  dismissButtonClick() {
    const opts = { type: "PUT" };
    const dismissTypes = this.filterByTypes;
    if (dismissTypes?.length > 0) {
      opts.data = { dismiss_types: dismissTypes.join(",") };
    }
    const modalController = this.dismissWarningModal();
    const modalCallback = () => {
      ajax("/notifications/mark-read", opts).then(() => {
        this.refreshList();
        postRNWebviewMessage("markRead", "1");
      });
    };
    if (modalController) {
      modalController.set("dismissNotifications", modalCallback);
    } else {
      modalCallback();
    }
  }
}
