import { withPluginApi } from 'discourse/lib/plugin-api';
import { ajax } from 'discourse/lib/ajax';

const propertyPath = "custom_fields.mmn_auto_respond_pm";
const glyph = {
  className: "pm-auto-responder-icon",
  icon: "power-off",
  action: "toggleAutoRespondPm"
};

let loading = false;

function iconLabel(enabled) {
  const iconLabel = enabled ? "disable" : "enable";
  return `mmn_auto_respond_pm.${iconLabel}`;
}

function setClassAndLabel(enabled) {
  const className = "pm-auto-responder-on";
  const method = enabled ? "add" : "remove";

  $("html")[`${method}Class`](className);
  glyph.label = iconLabel(enabled);
}

function toggleAutoRespondPm(user) {
  const path = user.get(propertyPath) ? "disable" : "enable";

  user.toggleProperty(propertyPath);
  loading = true;

  ajax(`/mmn_auto_respond_pm/${path}`)
    .catch( e => console.error(e) )
    .then(result => {
      if (result.status != "ok") user.toggleProperty(propertyPath);
    }).finally( () => {
      setClassAndLabel(user.get(propertyPath));
      loading = false;
    });
}

function initializeWithApi(api, siteSetting) {

  if (!siteSetting.enable_pm_auto_responder_for_admins) return;

  const currentUser = api.getCurrentUser();

  if (!currentUser || !currentUser.get('admin')) return;

  setClassAndLabel(currentUser.get(propertyPath));

  api.addUserMenuGlyph(glyph);

  api.attachWidgetAction("user-menu", 'toggleAutoRespondPm', function() {
    const { currentUser, siteSettings } = this;
    if (!siteSettings.enable_pm_auto_responder_for_admins || loading) { return; }
    toggleAutoRespondPm(currentUser);
  });

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
