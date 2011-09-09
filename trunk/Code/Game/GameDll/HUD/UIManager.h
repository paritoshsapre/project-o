#ifndef __UIManager_H__
#define __UIManager_H__

class CUIInput;
class CUIObjectives;
class CUISettings;

class CUIManager
{
public:
	static void Init();
	static void Destroy();
	static CUIManager* GetInstance();

	CUIObjectives* GetUIObjectives();
	CUIInput* GetUIInput();

	void UpdatePickupMessage(bool bShow);

private:
	CUIManager();
	CUIManager(const CUIManager& ) {}
	CUIManager operator=(const CUIManager& ) {}
	~CUIManager();

	static CUIManager* m_pInstance;

private:
	CUIInput* m_pUIInput;
	CUIObjectives* m_pUIObjectives;
	CUISettings* m_pUISettings;

	bool m_bPickupMsgVisible;
};

#endif

