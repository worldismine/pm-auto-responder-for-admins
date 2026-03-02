import Component from "@glimmer/component";
import { service } from "@ember/service";
import AutoPmToggler from "../../components/auto-pm-toggler";

export default class PmAutoResponderButton extends Component {
  @service currentUser;

  get showInSidebar() {
    return this.currentUser?.admin;
  }

  <template>
    {{#if this.showInSidebar}}
      <AutoPmToggler />
    {{/if}}
  </template>
}