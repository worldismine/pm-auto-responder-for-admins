import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/components/d-button";
import bodyClass from "discourse/helpers/body-class";

export default class AutoPmToggler extends Component {
  @service currentUser;

  get toggleButtonIcon() {
    return "power-off";
  }

  get isResponderOn() {
    return this.currentUser.get("custom_fields.mmn_auto_respond_pm");
  }

  get getTitle() {
    return this.isResponderOn
      ? "mmn_auto_respond_pm.disable"
      : "mmn_auto_respond_pm.enable";
  }

  @action
  toggleAutoPm() {
    const propertyPath = "custom_fields.mmn_auto_respond_pm";
    const path = this.isResponderOn ? "disable" : "enable";

    // Toggle local state immediately (triggers the template to update bodyClass & title)
    this.currentUser.toggleProperty(propertyPath);

    ajax(`/mmn_auto_respond_pm/${path}`)
      .then((result) => {
        if (result.status !== "ok") {
          // Revert if API failed
          this.currentUser.toggleProperty(propertyPath);
        }
      })
      .catch((e) => console.error(e));
  }

  <template>
    {{#if this.isResponderOn}}
      {{bodyClass "pm-auto-responder-on"}}
    {{/if}}

    <DButton
      @action={{this.toggleAutoPm}}
      @icon={{this.toggleButtonIcon}}
      class="auto-pm-toggler btn-flat"
      @title={{this.getTitle}}
    />
  </template>
}