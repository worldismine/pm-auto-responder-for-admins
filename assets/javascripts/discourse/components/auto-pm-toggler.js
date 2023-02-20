import Component from "@glimmer/component";
import { action, computed } from "@ember/object";
import { inject as service } from "@ember/service";
import { ajax } from 'discourse/lib/ajax';
import { observes } from "discourse-common/utils/decorators";

export default class AutoPmToggler extends Component {
  @service currentUser;

  constructor() {
    super(...arguments);
  }

  @computed("storedOverride")
  get toggleButtonIcon() {
      return "power-off";
  }

  get getTitle() {
    const propertyPath = "custom_fields.mmn_auto_respond_pm";
    return this.currentUser.get(propertyPath) ? "mmn_auto_respond_pm.disable" : "mmn_auto_respond_pm.enable";
  }

  setClassAndLabel(enabled) {
    const className = "pm-auto-responder-on";
    const method = enabled ? "add" : "remove";
  
    $("html")[`${method}Class`](className);
  }

  @action
  toggleAutoPm() {
    const propertyPath = "custom_fields.mmn_auto_respond_pm";
    const path = this.currentUser.get(propertyPath) ? "disable" : "enable";

    this.currentUser.toggleProperty(propertyPath);

    var loading = true;
    var _this = this;

    ajax(`/mmn_auto_respond_pm/${path}`)
      .catch( e => console.error(e) )
      .then(result => {
        if (result.status != "ok") {
          _this.currentUser.toggleProperty(propertyPath);
        }
      }).finally( () => {
        _this.setClassAndLabel(_this.currentUser.get(propertyPath));
        loading = false;
      });
  }
}
