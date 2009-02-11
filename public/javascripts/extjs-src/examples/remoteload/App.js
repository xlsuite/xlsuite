Ext.onReady(function(){
	new App.EmployeeStore({
		storeId: 'employeeStore',
		url: 'loadStore.php'
	});
	Ext.ux.ComponentLoader.load({
		url: 'sampleApp.php',
		params: {
			testing: 'Testing params'
		}
	});
});
