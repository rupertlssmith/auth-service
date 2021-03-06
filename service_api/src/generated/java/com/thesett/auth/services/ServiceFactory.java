package com.thesett.auth.services;

import com.thesett.auth.services.AccountService;

import com.thesett.auth.services.RoleService;

import com.thesett.auth.services.PermissionService;


/**
 * ServiceFactory describes a factory for creating clients to access the services built on the top-level
 * entities.
 */    
public interface ServiceFactory {

    /**
     * Supplies a proxied instance of the AccountService.
     *
     * @return A proxied instance of the AccountService.
     */
    AccountService getAccountService();

    /**
     * Supplies a proxied instance of the RoleService.
     *
     * @return A proxied instance of the RoleService.
     */
    RoleService getRoleService();

    /**
     * Supplies a proxied instance of the PermissionService.
     *
     * @return A proxied instance of the PermissionService.
     */
    PermissionService getPermissionService();

}