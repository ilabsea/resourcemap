SitesPermission = {
  fetch: function(collectionId, callback){
    $.ajax({
      url: "/mobile/collections/" + collectionId + "/sites_permission",
      async: false,
      success: callback
    });
  },
  allRule: function(collectionId, siteId){
    var none = false;
    var canRead = false;
    var canWrite = false;
    SitesPermission.fetch(collectionId, function(sites){
      none = SitesPermission.none(siteId, sites);
      canRead = SitesPermission.canRead(siteId, sites);
      canWrite = SitesPermission.canWrite(siteId, sites);
    });
    accessRight = {none: none, canRead: canRead, canWrite: canWrite};
    return accessRight;
  },
  none: function(siteId, sites){
    return SitesPermission.helperRule(siteId, sites.none);
  },
  canRead: function(siteId, sites){
    return SitesPermission.helperRule(siteId, sites.read);
  },
  canWrite: function(siteId, sites){
    return SitesPermission.helperRule(siteId, sites.write);
  },
  helperRule: function(siteId, rule){
    var helper = false;
    if(rule){
      if(!rule.allSites){
        $.map(rule.some_sites, function(site){
          if(site.id == siteId){
            helper = true;
            return;
          }
        });
      }
    }
    return helper;
  }
}