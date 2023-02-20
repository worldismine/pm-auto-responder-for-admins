import { withPluginApi } from 'discourse/lib/plugin-api';

const propertyPath = "custom_fields.mmn_auto_respond_pm";

function setClassAndLabel(enabled) {
  const className = "pm-auto-responder-on";
  const method = enabled ? "add" : "remove";

  $("html")[`${method}Class`](className);
}

function initializeWithApi(api, siteSetting) {
  if (!siteSetting.enable_pm_auto_responder_for_admins) return;
  const currentUser = api.getCurrentUser();
  if (!currentUser || !currentUser.get('admin')) return;
  setClassAndLabel(currentUser.get(propertyPath));
}

export default {
  name: 'extend-for-pm-auto-responder',
  initialize(c) {
    const siteSetting = c.lookup('site-settings:main');
    withPluginApi('0.1', api => {
      initializeWithApi(api, siteSetting);
    });
  }
}
