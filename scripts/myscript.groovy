import com.liferay.portal.kernel.model.User;
import com.liferay.portal.kernel.service.ServiceContext;
import com.liferay.portal.kernel.service.ServiceContextFactory;
import com.liferay.portal.kernel.service.UserLocalServiceUtil;
import com.liferay.portal.kernel.service.GroupLocalServiceUtil;
import com.liferay.portal.kernel.util.PortalUtil;

ServiceContext serviceContext = new ServiceContext();

long defaultCompanyId = PortalUtil.getDefaultCompanyId();
println("Company Id: " + defaultCompanyId);

User creatorUser = UserLocalServiceUtil.getDefaultUser(defaultCompanyId);
println("Default User Id: " + creatorUser.getUserId());

long creatorUserId = creatorUser.getUserId();

long companyId = creatorUser.getCompanyId();
println("Company Id2: " + companyId);

def companyGroup = GroupLocalServiceUtil.getCompanyGroup(defaultCompanyId);
serviceContext.setScopeGroupId(companyGroup.getGroupId());

Locale locale = creatorUser.getLocale();
String password = 'test';
String screenNameBase = 'User';
String emailBase = '@liferay.com';

def group = GroupLocalServiceUtil.fetchFriendlyURLGroup(companyId,'/guest');
long[] groupIds = new long[1];

groupIds = [ group.getGroupId() ];

for (int i = 1; i <= 2; i++) {
    String screenName = screenNameBase + i;
    int birthYear = i % 100 + 1910;
  UserLocalServiceUtil.addUserWithWorkflow(
        creatorUserId, companyId, false, password, password, false, screenName,
        screenName + emailBase, locale, screenName, '', 'User', 0, 0,
        true, i % 12, i % 28 + 1, birthYear, '', 1, groupIds, null, null, null, false,
        serviceContext);

        System.out.println('Added ' + i + ' users so far');
}