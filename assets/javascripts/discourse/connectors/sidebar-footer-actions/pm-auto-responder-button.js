export default {
  setupComponent(_args, component) {
    component.showInSidebar = this?.currentUser && this.currentUser.admin;
  },
};