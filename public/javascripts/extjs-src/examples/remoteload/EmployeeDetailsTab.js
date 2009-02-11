Ext.ns('App');

App.EmployeeDetailsTab = Ext.extend(Ext.TabPanel, {
	load: function(employeeId) {
		this.items.each(function(i) {
			if (i.load) {
				i.load({
					params: {
						employeeId: employeeId
					}
				});				
			}
		});
	}
});
Ext.reg('employeedetailstab', App.EmployeeDetailsTab);
